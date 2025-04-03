from django.contrib.gis import admin
from django.contrib.gis.admin import OSMGeoAdmin
from .models import (
    Category,
    Place,
    City,
    TouristPoint,
    Restaurant,
    Event,
    Itinerary,
    ItineraryStop,
    ItineraryTheme,
    UserTouristPointVisit,
)


from django.contrib.auth.admin import UserAdmin
# from .models import CustomUser  # Temporalmente comentado

# -----------------------------
# MODELOS EXISTENTES
# -----------------------------
admin.site.register(Category)

class CustomGeoAdmin(admin.GISModelAdmin):
    gis_widget_kwargs = {
        'attrs': {
            'default_zoom': 4,
            'default_lon': 133.74, 
            'default_lat': -24.06
        }
    }

@admin.register(Place)
class PlaceAdmin(CustomGeoAdmin):
    pass

@admin.register(City)
class CityAdmin(CustomGeoAdmin):
    pass

#NEW!!!!!!!!!!
# ------------------------------
# TouristPoint (con mapa)
# ------------------------------
@admin.register(TouristPoint)
class TouristPointAdmin(OSMGeoAdmin):
    list_display = ('name', 'category')
    search_fields = ('name',)
    list_filter = ('category',)

# ------------------------------
# Restaurant (con mapa opcional)
# ------------------------------
@admin.register(Restaurant)
class RestaurantAdmin(OSMGeoAdmin):
    list_display = ('name', 'phone')
    search_fields = ('name',)

# ------------------------------
# Event (con mapa)
# ------------------------------
@admin.register(Event)
class EventAdmin(OSMGeoAdmin):
    list_display = ('name', 'start_time', 'end_time')
    search_fields = ('name',)
    list_filter = ('start_time',)

# ------------------------------
# ItineraryTheme
# ------------------------------
@admin.register(ItineraryTheme)
class ItineraryThemeAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ('name',)

# ------------------------------
# ItineraryStop Inline (para ver paradas dentro de itinerarios)
# ------------------------------
class ItineraryStopInline(admin.TabularInline):
    model = ItineraryStop
    extra = 1
    fields = ('point', 'day', 'order')
    ordering = ('day', 'order')

# ------------------------------
# Itinerary
# ------------------------------
@admin.register(Itinerary)
class ItineraryAdmin(admin.ModelAdmin):
    list_display = ('name', 'estimated_duration', 'difficulty', 'num_days')
    search_fields = ('name', 'description')
    list_filter = ('difficulty', 'themes')
    filter_horizontal = ('themes',)
    inlines = [ItineraryStopInline]

# ------------------------------
# ItineraryStop (vista independiente)
# ------------------------------
@admin.register(ItineraryStop)
class ItineraryStopAdmin(admin.ModelAdmin):
    list_display = ('itinerary', 'day', 'order', 'point')
    ordering = ('itinerary', 'day', 'order')
    list_filter = ('day', 'itinerary')

# ------------------------------
# UserTouristPointVisit
# ------------------------------
@admin.register(UserTouristPointVisit)
class UserTouristPointVisitAdmin(admin.ModelAdmin):
    list_display = ('user', 'point', 'visited', 'visited_at')
    list_filter = ('visited', 'visited_at')
    search_fields = ('user__username', 'point__name')




# @admin.register(CustomUser)
# class CustomUserAdmin(UserAdmin):
#     model = CustomUser
#     list_display = ['username', 'email', 'is_staff', ]