from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from .models import User, Operator, Vehicle, Route, Schedule, Seat, Booking, Payment
from .serializers import (
    RegisterSerializer, UserSerializer, RouteSerializer, 
    ScheduleSerializer, ScheduleCreateSerializer,
    SeatSerializer, BookingSerializer, VehicleSerializer,
)
from .utils.mpesa import initiate_stk_push
from django.utils import timezone
import datetime
from rest_framework.exceptions import ValidationError

# Authentication Views
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    def get_object(self):
        return self.request.user

# Route & Trip Views
class RouteListView(generics.ListAPIView):
    queryset = Route.objects.all()
    serializer_class = RouteSerializer
    permission_classes = (permissions.AllowAny,)

    def get_queryset(self):
        origin = self.request.query_params.get('origin')
        destination = self.request.query_params.get('destination')
        queryset = Route.objects.all()
        if origin:
            queryset = queryset.filter(origin__icontains=origin)
        if destination:
            queryset = queryset.filter(destination__icontains=destination)
        return queryset

class ScheduleListView(generics.ListAPIView):
    serializer_class = ScheduleSerializer
    permission_classes = (permissions.AllowAny,)

    def get_queryset(self):
        route_id = self.request.query_params.get('route_id')
        origin = self.request.query_params.get('origin')
        destination = self.request.query_params.get('destination')
        date = self.request.query_params.get('date')
        
        with open("request_debug.log", "a") as f:
            f.write(f"Incoming Request: origin={origin}, destination={destination}, date={date}\n")
        
        queryset = Schedule.objects.select_related('route', 'vehicle').all()
        
        if route_id:
            queryset = queryset.filter(route_id=route_id)
        if origin:
            queryset = queryset.filter(route__origin__icontains=origin)
        if destination:
            queryset = queryset.filter(route__destination__icontains=destination)
        if date:
            queryset = queryset.filter(departure_datetime__date=date)
            
        return queryset.order_by('departure_datetime')

class SeatListView(generics.ListAPIView):
    serializer_class = SeatSerializer
    permission_classes = (permissions.AllowAny,)

    def get_queryset(self):
        schedule_id = self.request.query_params.get('schedule_id')
        if not schedule_id:
            return Seat.objects.none()
        try:
            schedule = Schedule.objects.select_related('vehicle').get(id=schedule_id)
            return Seat.objects.filter(vehicle=schedule.vehicle)
        except Schedule.DoesNotExist:
            return Seat.objects.none()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['schedule_id'] = self.request.query_params.get('schedule_id')
        return context

# Booking Views
class BookingCreateView(generics.CreateAPIView):
    serializer_class = BookingSerializer

    def perform_create(self, serializer):
        schedule = serializer.validated_data['schedule']
        seats = serializer.validated_data.get('seats', [])
        
        # Cleanup expired bookings for this schedule
        expiry_threshold = timezone.now() - datetime.timedelta(minutes=15)
        Booking.objects.filter(
            schedule=schedule, 
            status=Booking.Status.PENDING_PAYMENT, 
            created_at__lt=expiry_threshold
        ).update(status=Booking.Status.CANCELLED)
        
        # Check if any seat is already booked for this schedule
        for seat in seats:
            if Booking.objects.filter(
                schedule=schedule, 
                seats=seat, 
                status__in=[Booking.Status.CONFIRMED, Booking.Status.PENDING_PAYMENT, Booking.Status.PENDING_VERIFICATION]
            ).exists():
                raise ValidationError(f"Seat {seat.seat_number} is already booked.")
            
        transaction_code = self.request.data.get('transaction_code')
        booking_status = Booking.Status.PENDING_VERIFICATION if transaction_code else Booking.Status.PENDING_PAYMENT

        serializer.save(user=self.request.user, status=booking_status)

class MyBookingsView(generics.ListAPIView):
    serializer_class = BookingSerializer

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user).order_by('-created_at')

# Payment Views
class STKPushView(APIView):
    def post(self, request):
        booking_id = request.data.get('booking_id')
        phone_number = request.data.get('phone_number')
        
        try:
            booking = Booking.objects.get(id=booking_id, user=request.user)
        except Booking.DoesNotExist:
            return Response({"error": "Booking not found"}, status=status.HTTP_404_NOT_FOUND)
            
        # Initiate STK Push
        response, error = initiate_stk_push(phone_number, booking.amount, booking.booking_reference)
        
        if error:
            return Response({"error": error}, status=status.HTTP_400_BAD_REQUEST)
            
        # Create or update Payment record
        payment, created = Payment.objects.get_or_create(
            booking=booking,
            defaults={
                'phone_number': phone_number,
                'amount': booking.amount,
                'merchant_request_id': response.get('MerchantRequestID'),
                'checkout_request_id': response.get('CheckoutRequestID'),
                'status': Payment.Status.PENDING
            }
        )
        if not created:
            payment.merchant_request_id = response.get('MerchantRequestID')
            payment.checkout_request_id = response.get('CheckoutRequestID')
            payment.status = Payment.Status.PENDING
            payment.save()
            
        return Response(response)

class MPesaCallbackView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        data = request.data
        callback_data = data.get('Body', {}).get('stkCallback', {})
        
        merchant_request_id = callback_data.get('MerchantRequestID')
        checkout_request_id = callback_data.get('CheckoutRequestID')
        result_code = callback_data.get('ResultCode')
        result_desc = callback_data.get('ResultDesc')
        
        try:
            payment = Payment.objects.get(
                merchant_request_id=merchant_request_id,
                checkout_request_id=checkout_request_id
            )
        except Payment.DoesNotExist:
            return Response({"error": "Payment record not found"}, status=status.HTTP_404_NOT_FOUND)
            
        payment.result_code = result_code
        payment.result_desc = result_desc
        payment.callback_payload = data
        
        if result_code == 0:
            payment.status = Payment.Status.PAID
            payment.paid_at = timezone.now()
            
            items = callback_data.get('CallbackMetadata', {}).get('Item', [])
            for item in items:
                if item.get('Name') == 'MpesaReceiptNumber':
                    payment.mpesa_receipt_number = item.get('Value')
                    break
            
            booking = payment.booking
            booking.status = Booking.Status.CONFIRMED
            booking.save()
        else:
            payment.status = Payment.Status.FAILED
            booking = payment.booking
            booking.status = Booking.Status.CANCELLED
            booking.save()
            
from rest_framework import viewsets

class PaymentStatusView(APIView):
    def get(self, request, checkout_request_id):
        try:
            payment = Payment.objects.get(checkout_request_id=checkout_request_id)
            return Response({
                "status": payment.status,
                "result_code": payment.result_code,
                "result_desc": payment.result_desc,
                "paid_at": payment.paid_at,
                "mpesa_receipt_number": payment.mpesa_receipt_number
            })
        except Payment.DoesNotExist:
            return Response({"error": "Payment not found"}, status=status.HTTP_404_NOT_FOUND)

# Operator Management Views
class IsOperator(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == User.Role.OPERATOR

class OperatorVehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [IsOperator]

    def get_queryset(self):
        return Vehicle.objects.filter(operator__user=self.request.user)

    def perform_create(self, serializer):
        operator = Operator.objects.get(user=self.request.user)
        serializer.save(operator=operator)

class OperatorRouteViewSet(viewsets.ModelViewSet):
    serializer_class = RouteSerializer
    permission_classes = [IsOperator]
    queryset = Route.objects.all() # Routes are global for now, but operators can see them

class OperatorScheduleViewSet(viewsets.ModelViewSet):
    serializer_class = ScheduleSerializer
    permission_classes = [IsOperator]

    def get_queryset(self):
        return Schedule.objects.filter(vehicle__operator__user=self.request.user)

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return ScheduleCreateSerializer
        return ScheduleSerializer


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == User.Role.ADMIN


class PendingVerificationsView(generics.ListAPIView):
    """Admin view: list all bookings awaiting manual transaction code verification."""
    serializer_class = BookingSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        return Booking.objects.filter(
            status=Booking.Status.PENDING_VERIFICATION
        ).select_related('user', 'schedule', 'schedule__route').order_by('-created_at')


class ApproveBookingView(APIView):
    """Admin view: approve or reject a booking pending manual verification."""
    permission_classes = [IsAdmin]

    def post(self, request, booking_id):
        action = request.data.get('action')  # 'approve' or 'reject'
        try:
            booking = Booking.objects.get(id=booking_id, status=Booking.Status.PENDING_VERIFICATION)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found or not pending verification.'}, status=status.HTTP_404_NOT_FOUND)

        if action == 'approve':
            booking.status = Booking.Status.CONFIRMED
            booking.save()
            
            # Record the manual payment
            Payment.objects.update_or_create(
                booking=booking,
                defaults={
                    'phone_number': booking.passenger_phone,
                    'amount': booking.amount,
                    'mpesa_receipt_number': booking.transaction_code, # Use manual code as receipt
                    'status': Payment.Status.PAID,
                    'paid_at': timezone.now(),
                    'result_desc': 'Manually approved by admin'
                }
            )
            return Response({'message': f'Booking {booking.booking_reference} has been confirmed.'}, status=status.HTTP_200_OK)
        elif action == 'reject':
            booking.status = Booking.Status.CANCELLED
            booking.save()
            return Response({'message': f'Booking {booking.booking_reference} has been cancelled.'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Invalid action. Use "approve" or "reject".'}, status=status.HTTP_400_BAD_REQUEST)
