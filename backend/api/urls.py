from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import (
    RegisterView, ProfileView, RouteListView, 
    ScheduleListView, SeatListView, BookingCreateView, MyBookingsView,
    STKPushView, MPesaCallbackView, PaymentStatusView,
    OperatorVehicleViewSet, OperatorRouteViewSet, OperatorScheduleViewSet,
    PendingVerificationsView, ApproveBookingView,
)

urlpatterns = [
    # Auth endpoints
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/profile/', ProfileView.as_view(), name='profile'),

    # Search & Trips endpoints
    path('routes/', RouteListView.as_view(), name='route-list'),
    path('schedules/', ScheduleListView.as_view(), name='schedule-list'),
    path('seats/', SeatListView.as_view(), name='seat-list'),

    # Booking endpoints
    path('bookings/', BookingCreateView.as_view(), name='booking-create'),
    path('bookings/my/', MyBookingsView.as_view(), name='my-bookings'),

    # Admin endpoints
    path('admin/pending-verifications/', PendingVerificationsView.as_view(), name='pending-verifications'),
    path('admin/bookings/<uuid:booking_id>/approve/', ApproveBookingView.as_view(), name='approve-booking'),

    # Payment endpoints
    path('payments/mpesa/stk-push/', STKPushView.as_view(), name='mpesa-stk-push'),
    path('payments/mpesa/callback/', MPesaCallbackView.as_view(), name='mpesa-callback'),
    path('payments/status/<str:checkout_request_id>/', PaymentStatusView.as_view(), name='payment-status'),
]

from rest_framework.routers import DefaultRouter
router = DefaultRouter()
router.register('operator/vehicles', OperatorVehicleViewSet, basename='operator-vehicles')
router.register('operator/routes', OperatorRouteViewSet, basename='operator-routes')
router.register('operator/schedules', OperatorScheduleViewSet, basename='operator-schedules')

urlpatterns += router.urls
