"""
Management command to seed the database with test data for TwendeGo.
Run with: python manage.py seed_data
"""
import django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import User, Operator, Vehicle, Route, BoardingPoint, Schedule, Seat
from django.utils import timezone
from datetime import timedelta

print("=== Seeding TwendeGo Test Data ===")

# 1. Create Superuser / Admin
if not User.objects.filter(phone_number='0700000000').exists():
    admin = User.objects.create_superuser(
        username='admin',
        phone_number='0700000000',
        password='Admin@1234',
        role=User.Role.ADMIN
    )
    print(f"✅ Admin created: {admin.phone_number} / Admin@1234")
else:
    admin = User.objects.get(phone_number='0700000000')
    print("ℹ️  Admin already exists")

# 2. Create Operator User
if not User.objects.filter(phone_number='0711111111').exists():
    op_user = User.objects.create_user(
        username='tahmeed_ops',
        phone_number='0711111111',
        password='Operator@1234',
        role=User.Role.OPERATOR
    )
    print(f"✅ Operator user created: {op_user.phone_number} / Operator@1234")
else:
    op_user = User.objects.get(phone_number='0711111111')
    print("ℹ️  Operator user already exists")

# 3. Create Operator Profile
if not hasattr(op_user, 'operator_profile'):
    operator = Operator.objects.create(
        user=op_user,
        company_name='TwendeGo Express',
        license_number='TG-2024-001',
        is_approved=True
    )
    print(f"✅ Operator profile created: {operator.company_name}")
else:
    operator = op_user.operator_profile
    print("ℹ️  Operator profile already exists")

# 4. Create Vehicle
if not Vehicle.objects.filter(plate_number='KDA 123A').exists():
    vehicle = Vehicle.objects.create(
        operator=operator,
        plate_number='KDA 123A',
        vehicle_type='45-Seater Coach',
        seat_capacity=45
    )
    print(f"✅ Vehicle created: {vehicle.plate_number}")
    # Create seats for the vehicle
    for i in range(1, 46):
        row = (i - 1) // 4
        col = (i - 1) % 4
        label = f"{'ABCD'[col]}{row + 1}" if col < 4 else f"E{row + 1}"
        Seat.objects.create(vehicle=vehicle, seat_number=str(i), seat_label=label)
    print(f"   → 45 seats created")
else:
    vehicle = Vehicle.objects.get(plate_number='KDA 123A')
    print("ℹ️  Vehicle already exists")

# 5. Create Routes
routes_data = [
    ('Nairobi', 'Mombasa', 480, 8),
    ('Nairobi', 'Kisumu', 340, 6),
    ('Nairobi', 'Nakuru', 160, 3),
    ('Nairobi', 'Eldoret', 310, 5),
    ('Mombasa', 'Malindi', 120, 2),
]

routes = {}
for origin, dest, dist, hours in routes_data:
    key = f"{origin}-{dest}"
    if not Route.objects.filter(origin=origin, destination=dest).exists():
        route = Route.objects.create(
            origin=origin,
            destination=dest,
            distance_km=dist,
            estimated_duration=timedelta(hours=hours)
        )
        # Add boarding points
        BoardingPoint.objects.create(route=route, point_name=f'{origin} CBD', sequence_order=1)
        BoardingPoint.objects.create(route=route, point_name=f'{dest} Terminal', sequence_order=2)
        routes[key] = route
        print(f"✅ Route created: {origin} → {dest}")
    else:
        routes[key] = Route.objects.get(origin=origin, destination=dest)
        print(f"ℹ️  Route exists: {origin} → {dest}")

# 6. Create Schedules for the next 3 days
tomorrow = timezone.now().replace(hour=6, minute=0, second=0, microsecond=0) + timedelta(days=1)
schedule_count = 0
nairobi_mombasa = routes.get('Nairobi-Mombasa')
nairobi_kisumu = routes.get('Nairobi-Kisumu')

schedules_to_create = [
    (nairobi_mombasa, 0, '07:00', 1500),
    (nairobi_mombasa, 0, '10:00', 1500),
    (nairobi_mombasa, 1, '07:00', 1500),
    (nairobi_kisumu, 0, '08:00', 1200),
    (nairobi_kisumu, 1, '09:00', 1200),
]

for route, day_offset, time_str, fare in schedules_to_create:
    if route is None:
        continue
    h, m = map(int, time_str.split(':'))
    dep = (tomorrow + timedelta(days=day_offset)).replace(hour=h, minute=m)
    arr = dep + timedelta(hours=8 if 'Mombasa' in route.destination else 6)
    if not Schedule.objects.filter(route=route, departure_datetime=dep).exists():
        Schedule.objects.create(
            route=route,
            vehicle=vehicle,
            departure_datetime=dep,
            arrival_estimate=arr,
            fare=fare,
            status=Schedule.Status.SCHEDULED
        )
        schedule_count += 1

print(f"✅ {schedule_count} schedule(s) created")

print("\n=== Seeding Complete! ===")
print("Admin Panel:  http://localhost:8080/admin/")
print("  Login:      0700000000 / Admin@1234")
print("API Root:     http://localhost:8080/api/")
print("Routes:       http://localhost:8080/api/routes/")
print("Schedules:    http://localhost:8080/api/schedules/")
