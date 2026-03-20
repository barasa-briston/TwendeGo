from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Operator, Vehicle, Route, BoardingPoint, Schedule, Seat, Booking, Payment

class CustomUserAdmin(UserAdmin):
    model = User
    list_display = ['phone_number', 'username', 'role', 'is_staff']
    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('role', 'phone_number')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        (None, {'fields': ('role', 'phone_number')}),
    )

admin.site.register(User, CustomUserAdmin)
admin.site.register(Operator)
admin.site.register(Vehicle)
admin.site.register(Route)
admin.site.register(BoardingPoint)
admin.site.register(Schedule)
admin.site.register(Seat)

class PaymentInline(admin.StackedInline):
    model = Payment
    extra = 0
    can_delete = False
    readonly_fields = ['created_at', 'paid_at', 'callback_payload']

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ['booking_reference', 'passenger_name', 'status', 'amount', 'transaction_code', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['booking_reference', 'passenger_name', 'passenger_phone', 'transaction_code']
    inlines = [PaymentInline]
    readonly_fields = ['booking_reference', 'created_at']

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['booking', 'amount', 'status', 'mpesa_receipt_number', 'paid_at', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['mpesa_receipt_number', 'phone_number', 'booking__booking_reference']
    readonly_fields = ['created_at', 'paid_at', 'callback_payload']
