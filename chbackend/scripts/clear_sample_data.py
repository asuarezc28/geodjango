from chbackend.models import (
    TouristPoint,
    Restaurant,
    Event,
    Itinerary,
    ItineraryStop,
    ItineraryTheme,
    UserTouristPointVisit
)

def run():
    print("🧹 Borrando datos de prueba...")

    UserTouristPointVisit.objects.all().delete()
    ItineraryStop.objects.all().delete()
    Itinerary.objects.all().delete()
    ItineraryTheme.objects.all().delete()
    TouristPoint.objects.all().delete()
    Restaurant.objects.all().delete()
    Event.objects.all().delete()

    print("✅ ¡Todos los datos de ejemplo han sido eliminados!")