from django.contrib.gis.geos import Point
from chbackend.models import (
    TouristPoint,
    Restaurant,
    Event,
    Itinerary,
    ItineraryStop,
    ItineraryTheme,
)
from datetime import datetime, timedelta

def run():
    # Limpiar anteriores
    TouristPoint.objects.all().delete()
    Restaurant.objects.all().delete()
    Event.objects.all().delete()
    Itinerary.objects.all().delete()
    ItineraryTheme.objects.all().delete()

    print("⏳ Insertando datos de prueba...")

    # 🌿 Temas
    sostenible = ItineraryTheme.objects.create(name="Sostenible", description="Rutas respetuosas con el medio ambiente")
    cultural = ItineraryTheme.objects.create(name="Cultural", description="Explora el patrimonio y tradiciones")

    # 🌋 Tourist Points
    cumbrecita = TouristPoint.objects.create(
        name="Mirador de La Cumbrecita",
        description="Uno de los miradores más espectaculares del Parque Nacional de la Caldera de Taburiente.",
        location=Point(-17.8805, 28.7564),
        category="mirador"
    )

    san_antonio = TouristPoint.objects.create(
        name="Volcán San Antonio",
        description="Ruta circular con vistas a Fuencaliente y al volcán Teneguía.",
        location=Point(-17.8663, 28.4805),
        category="sendero"
    )

    # 🍽️ Restaurantes
    Restaurant.objects.create(
        name="Casa Goyo",
        description="Famoso por su pescado fresco y por estar cerca del aeropuerto.",
        location=Point(-17.7511, 28.6234),
        phone="922123456",
        website="https://casagoyo.example.com"
    )

    Restaurant.objects.create(
        name="La Marmota Verde",
        description="Opciones vegetarianas y ecológicas con vista al mar.",
        location=Point(-17.9123, 28.6833),
        phone="922654321",
        website="https://lamarmotaverde.example.com"
    )

    # 🎭 Eventos
    Event.objects.create(
        name="Festival del Queso 2025",
        description="Degustaciones, talleres y música tradicional.",
        location=Point(-17.9201, 28.6203),
        start_time=datetime.now() + timedelta(days=7),
        end_time=datetime.now() + timedelta(days=7, hours=5)
    )

    Event.objects.create(
        name="Senderismo bajo las estrellas",
        description="Ruta guiada nocturna por la zona volcánica.",
        location=Point(-17.8555, 28.4822),
        start_time=datetime.now() + timedelta(days=10),
        end_time=datetime.now() + timedelta(days=10, hours=3)
    )

    # 🧭 Itinerary + Stops
    itin = Itinerary.objects.create(
        name="3 días en la naturaleza",
        description="Ruta pensada para conectar con los paisajes naturales más icónicos.",
        estimated_duration=timedelta(days=3),
        difficulty="Moderada",
        num_days=3
    )
    itin.themes.add(sostenible, cultural)

    ItineraryStop.objects.create(itinerary=itin, point=cumbrecita, order=1, day=1)
    ItineraryStop.objects.create(itinerary=itin, point=san_antonio, order=2, day=2)

    print("✅ ¡Datos insertados con éxito!")
