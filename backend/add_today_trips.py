import os
import django
import datetime
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Route, Schedule, Vehicle

route = Route.objects.filter(origin__icontains='Nairobi', destination__icontains='Mombasa').first()
vehicle = Vehicle.objects.first()

if route and vehicle:
    now = timezone.now()
    schedules = [
        Schedule(
            route=route,
            vehicle=vehicle,
            departure_datetime=now + datetime.timedelta(hours=2),
            arrival_estimate=now + datetime.timedelta(hours=10),
            fare=1500.00
        ),
        Schedule(
            route=route,
            vehicle=vehicle,
            departure_datetime=now + datetime.timedelta(hours=5),
            arrival_estimate=now + datetime.timedelta(hours=13),
            fare=1500.00
        )
    ]
    Schedule.objects.bulk_create(schedules)
    print("Successfully added schedules for today between Nairobi and Mombasa!")
else:
    print("Could not find route or vehicle.")
