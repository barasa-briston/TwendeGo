from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Q
from .models import Operator, Vehicle, Route, BoardingPoint, Schedule, Seat, Booking, Payment

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'phone_number', 'username', 'email', 'role', 'dob', 'gender', 'full_name')

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('phone_number', 'username', 'email', 'password', 'role', 'dob', 'gender', 'full_name')

    def validate_phone_number(self, value):
        if User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("This phone number is already registered.")
        return value

    def validate_email(self, value):
        if value and User.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is already in use.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            phone_number=validated_data['phone_number'],
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            role=validated_data.get('role', User.Role.PASSENGER),
            dob=validated_data.get('dob'),
            gender=validated_data.get('gender'),
            full_name=validated_data.get('full_name')
        )
        return user

class OperatorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Operator
        fields = '__all__'

class BoardingPointSerializer(serializers.ModelSerializer):
    class Meta:
        model = BoardingPoint
        fields = '__all__'

class RouteSerializer(serializers.ModelSerializer):
    boarding_points = BoardingPointSerializer(many=True, read_only=True)

    class Meta:
        model = Route
        fields = ('id', 'origin', 'destination', 'distance_km', 'estimated_duration', 'boarding_points')

class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ('id', 'plate_number', 'vehicle_type', 'seat_capacity')

class ScheduleSerializer(serializers.ModelSerializer):
    route = RouteSerializer(read_only=True)
    vehicle = VehicleSerializer(read_only=True)
    available_seats_count = serializers.SerializerMethodField()

    class Meta:
        model = Schedule
        fields = ('id', 'route', 'vehicle', 'departure_datetime', 'arrival_estimate', 'fare', 'status', 'available_seats_count')

    def get_available_seats_count(self, obj):
        if not obj.vehicle:
            return 0
        total_seats = obj.vehicle.seats.count()
        booked_seats = Booking.objects.filter(schedule=obj, status__in=[Booking.Status.CONFIRMED, Booking.Status.PENDING_PAYMENT]).count()
        return total_seats - booked_seats

class SeatSerializer(serializers.ModelSerializer):
    is_booked = serializers.SerializerMethodField()

    class Meta:
        model = Seat
        fields = ('id', 'seat_number', 'seat_label', 'is_booked')

    def get_is_booked(self, obj):
        schedule_id = self.context.get('schedule_id')
        if not schedule_id:
            return False
        
        from django.utils import timezone
        import datetime
        expiry_threshold = timezone.now() - datetime.timedelta(minutes=15)
        
        return Booking.objects.filter(
            schedule_id=schedule_id, 
            seats=obj, 
            status__in=[Booking.Status.CONFIRMED, Booking.Status.PENDING_PAYMENT, Booking.Status.PENDING_VERIFICATION]
        ).filter(
            Q(status=Booking.Status.CONFIRMED) | 
            Q(status=Booking.Status.PENDING_VERIFICATION) |
            Q(status=Booking.Status.PENDING_PAYMENT, created_at__gte=expiry_threshold)
        ).exists()

class BookingSerializer(serializers.ModelSerializer):
    schedule_detail = ScheduleSerializer(source='schedule', read_only=True)
    seats_detail = SeatSerializer(source='seats', many=True, read_only=True)

    class Meta:
        model = Booking
        fields = '__all__'
        read_only_fields = ('user', 'booking_reference', 'status', 'created_at')

class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'

class VehicleCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ('id', 'plate_number', 'vehicle_type', 'seat_capacity')

class ScheduleCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Schedule
        fields = ('id', 'route', 'vehicle', 'departure_datetime', 'arrival_estimate', 'fare', 'status')
