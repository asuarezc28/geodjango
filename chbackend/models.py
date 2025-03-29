from django.contrib.gis.db import models
from django.contrib.gis.db import models as geomodels
from django.conf import settings
from django.contrib.auth.models import AbstractUser

class Category(models.Model):
    category_name = models.CharField('Category name', max_length=50, help_text='s')
    created_at = models.DateTimeField(auto_now_add=True)
    modified_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Categories'

    def __str__(self):
        return self.category_name


class Place(models.Model):
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    place_name = models.CharField(max_length=50)
    description = models.CharField(max_length=254, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)  # Corregido create_at a created_at
    modified_at = models.DateTimeField(auto_now=True)
    image = models.ImageField(upload_to='place_images/', blank=True, null=True)
    point_geom = models.PointField()

    class Meta:
        verbose_name_plural = 'Places'

    def __str__(self):  # Indentado dentro de Place
        return self.place_name


class City(models.Model):  # Eliminado espacio extra
    name = models.CharField(max_length=50)
    point_geom = models.PointField()

    class Meta:  # Agregado Meta class
        verbose_name_plural = 'Cities'

    def __str__(self):  # Agregado __str__ method
        return self.name



from django.contrib.gis.db import models as geomodels

# ------------------------------
# MODELO: TouristPoint
# ------------------------------
class TouristPoint(geomodels.Model):
    CATEGORY_CHOICES = [
        ('mirador', 'Mirador'),
        ('sendero', 'Sendero'),
        ('playa', 'Playa'),
        ('monumento', 'Monumento'),
        ('otro', 'Otro'),
    ]

    name = geomodels.CharField(max_length=100)
    description = geomodels.TextField()
    location = geomodels.PointField()
    image = geomodels.ImageField(upload_to='tourist_points/', blank=True, null=True)
    category = geomodels.CharField(max_length=20, choices=CATEGORY_CHOICES)

    def __str__(self):
        return self.name

# ------------------------------
# MODELO: Restaurant
# ------------------------------
class Restaurant(geomodels.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    location = geomodels.PointField()
    image = models.ImageField(upload_to='restaurants/', blank=True, null=True)
    website = models.URLField(blank=True)
    phone = models.CharField(max_length=20, blank=True)

    def __str__(self):
        return self.name

# ------------------------------
# MODELO: Event
# ------------------------------
class Event(geomodels.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    location = geomodels.PointField()
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    image = models.ImageField(upload_to='events/', blank=True, null=True)

    def __str__(self):
        return self.name

# ------------------------------
# MODELO: ItineraryTheme
# ------------------------------
class ItineraryTheme(models.Model):
    name = models.CharField(max_length=50)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name

# ------------------------------
# MODELO: Itinerary
# ------------------------------
class Itinerary(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    estimated_duration = models.DurationField()
    difficulty = models.CharField(max_length=50, blank=True, null=True)
    num_days = models.PositiveIntegerField(default=1)  # Nuevo campo para indicar número de días
    themes = models.ManyToManyField(ItineraryTheme, related_name='itineraries')

    def __str__(self):
        return self.name

# ------------------------------
# MODELO: ItineraryStop
# ------------------------------
class ItineraryStop(models.Model):
    itinerary = models.ForeignKey(Itinerary, related_name='stops', on_delete=models.CASCADE)
    point = models.ForeignKey(TouristPoint, on_delete=models.CASCADE)
    order = models.PositiveIntegerField()
    day = models.PositiveIntegerField(default=1)  # Nuevo campo para indicar a qué día pertenece la parada

    class Meta:
        unique_together = ('itinerary', 'order')
        ordering = ['day', 'order']

    def __str__(self):
        return f"{self.itinerary.name} - Día {self.day} - {self.point.name} ({self.order})"

# ------------------------------
# MODELO: UserTouristPointVisit
# ------------------------------
class UserTouristPointVisit(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    point = models.ForeignKey(TouristPoint, on_delete=models.CASCADE)
    visited = models.BooleanField(default=False)
    visited_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        unique_together = ('user', 'point')

    def __str__(self):
        return f"{self.user.username} - {self.point.name} - {'✅' if self.visited else '❌'}"



        #CUSTOM USER
from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)

    def __str__(self):
        return self.username