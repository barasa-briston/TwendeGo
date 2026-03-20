from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
import uuid
import datetime

class User(AbstractUser):
    class Role(models.TextChoices):
        PASSENGER = 'PASSENGER', _('Passenger')
        OPERATOR = 'OPERATOR', _('Operator')
        ADMIN = 'ADMIN', _('Admin')

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(max_length=15, unique=True)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.PASSENGER)
    dob = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, null=True, blank=True)
    full_name = models.CharField(max_length=255, null=True, blank=True)
    
    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return self.phone_number

class Operator(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='operator_profile')
    company_name = models.CharField(max_length=255)
    license_number = models.CharField(max_length=100, unique=True)
    logo = models.ImageField(upload_to='operator_logos/', null=True, blank=True)
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.company_name

class Vehicle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    operator = models.ForeignKey(Operator, on_delete=models.CASCADE, related_name='vehicles')
    plate_number = models.CharField(max_length=20, unique=True)
    vehicle_type = models.CharField(max_length=50) # e.g., 14-seater, 45-seater
    seat_capacity = models.PositiveIntegerField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.plate_number} ({self.vehicle_type})"

class Route(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    origin = models.CharField(max_length=100, db_index=True)
    destination = models.CharField(max_length=100, db_index=True)
    distance_km = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    estimated_duration = models.DurationField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.origin} - {self.destination}"

class BoardingPoint(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    route = models.ForeignKey(Route, on_delete=models.CASCADE, related_name='boarding_points')
    point_name = models.CharField(max_length=255)
    sequence_order = models.PositiveIntegerField()

    class Meta:
        ordering = ['sequence_order']

    def __str__(self):
        return f"{self.point_name} ({self.route})"

class Schedule(models.Model):
    class Status(models.TextChoices):
        SCHEDULED = 'SCHEDULED', _('Scheduled')
        ACTIVE = 'ACTIVE', _('Active/On the Way')
        COMPLETED = 'COMPLETED', _('Completed')
        CANCELLED = 'CANCELLED', _('Cancelled')

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    route = models.ForeignKey(Route, on_delete=models.CASCADE, related_name='schedules')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.SET_NULL, null=True, related_name='schedules')
    departure_datetime = models.DateTimeField(db_index=True)
    arrival_estimate = models.DateTimeField()
    fare = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=15, choices=Status.choices, default=Status.SCHEDULED)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.route} at {self.departure_datetime}"

class Seat(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='seats')
    seat_number = models.CharField(max_length=5)
    seat_label = models.CharField(max_length=10, blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"Seat {self.seat_number} - {self.vehicle.plate_number}"

class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING_PAYMENT = 'PENDING_PAYMENT', _('Pending Payment')
        CONFIRMED = 'CONFIRMED', _('Confirmed')
        CANCELLED = 'CANCELLED', _('Cancelled')
        COMPLETED = 'COMPLETED', _('Completed')
        PENDING_VERIFICATION = 'PENDING_VERIFICATION', _('Pending Verification')

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bookings')
    schedule = models.ForeignKey(Schedule, on_delete=models.CASCADE, related_name='bookings')
    seats = models.ManyToManyField(Seat, related_name='bookings')
    passenger_name = models.CharField(max_length=255)
    passenger_phone = models.CharField(max_length=15, db_index=True)
    booking_reference = models.CharField(max_length=12, unique=True, editable=False)
    status = models.CharField(max_length=25, choices=Status.choices, default=Status.PENDING_PAYMENT)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_code = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.booking_reference:
            self.booking_reference = str(uuid.uuid4().hex[:12].upper())
        super().save(*args, **kwargs)

    @property
    def is_expired(self):
        from django.utils import timezone
        import datetime
        if self.status == self.Status.PENDING_PAYMENT:
            expiry_time = self.created_at + datetime.timedelta(minutes=15)
            return timezone.now() > expiry_time
        return False

    def __str__(self):
        return f"{self.booking_reference} - {self.passenger_name}"

class Payment(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING', _('Pending')
        PAID = 'PAID', _('Paid')
        FAILED = 'FAILED', _('Failed')
        CANCELLED = 'CANCELLED', _('Cancelled')

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='payment')
    phone_number = models.CharField(max_length=15)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    merchant_request_id = models.CharField(max_length=100, null=True, blank=True)
    checkout_request_id = models.CharField(max_length=100, null=True, blank=True)
    mpesa_receipt_number = models.CharField(max_length=100, null=True, blank=True)
    result_code = models.IntegerField(null=True, blank=True)
    result_desc = models.TextField(null=True, blank=True)
    status = models.CharField(max_length=15, choices=Status.choices, default=Status.PENDING)
    paid_at = models.DateTimeField(null=True, blank=True)
    callback_payload = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payment {self.id} for Booking {self.booking.booking_reference}"
