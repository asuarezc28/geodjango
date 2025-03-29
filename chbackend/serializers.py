from rest_framework import serializers
from .models import (
    TouristPoint,
    Restaurant,
    Event,
    ItineraryTheme,
    Itinerary,
    ItineraryStop,
    UserTouristPointVisit,
    Category,
    Place,
    City
)
from rest_framework_gis.serializers import GeoFeatureModelSerializer

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class PlaceSerializer(GeoFeatureModelSerializer):
    category = serializers.SlugRelatedField(
      queryset=Category.objects.all(),
      slug_field='category_name'
    )

    class Meta:
        model = Place
        geo_field = 'point_geom'
        fields = (
            'pk',
            'category',
            'place_name',
            'description',
            'created_at',
            'modified_at',
            'image'
        )


class CitySerializer(GeoFeatureModelSerializer):
    proximity = serializers.SerializerMethodField('get_proximity')
    def get_proximity(self, obj):
        if obj.distance:
            return obj.distance.km
        return False
    class Meta:
        model = City
        geo_field = 'point_geom'

        fields = (
            'pk',
            'name',
            'proximity'
        )





class TouristPointSerializer(serializers.ModelSerializer):
    class Meta:
        model = TouristPoint
        fields = '__all__'

class RestaurantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Restaurant
        fields = '__all__'

class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = '__all__'

class ItineraryThemeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ItineraryTheme
        fields = '__all__'

class ItinerarySerializer(serializers.ModelSerializer):
    themes = ItineraryThemeSerializer(many=True, read_only=True)

    class Meta:
        model = Itinerary
        fields = ['id', 'name', 'description', 'estimated_duration', 'difficulty', 'num_days', 'themes']

class ItineraryStopSerializer(serializers.ModelSerializer):
    point = TouristPointSerializer(read_only=True)

    class Meta:
        model = ItineraryStop
        fields = ['day', 'order', 'point']

class UserTouristPointVisitSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserTouristPointVisit
        fields = '__all__'