from django.shortcuts import render
from django.http import HttpResponse
from django.core.serializers import serialize
from .models import Place, Category, City

from .serializers import CategorySerializer
from .serializers import PlaceSerializer
from .serializers import CitySerializer
from rest_framework import generics
#to proximity
from django.http import Http404
from django.contrib.gis.db.models.functions import Distance
from django.shortcuts import get_object_or_404

from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import viewsets



#NEW!
from .models import (
    TouristPoint,
    Restaurant,
    Event,
    ItineraryTheme,
    Itinerary,
    ItineraryStop,
    UserTouristPointVisit,
)
from .serializers import (
    TouristPointSerializer,
    RestaurantSerializer,
    EventSerializer,
    ItineraryThemeSerializer,
    ItinerarySerializer,
    ItineraryStopSerializer,
    UserTouristPointVisitSerializer,
)



class CategoryList(generics.ListCreateAPIView):
   queryset = Category.objects.all()
   serializer_class = CategorySerializer
   name = 'category-list'

class CategoryDetail(generics.RetrieveUpdateDestroyAPIView):
  queryset = Category.objects.all()
  serializer_class = CategorySerializer
  name = 'category-detail'

class PlaceList(generics.ListCreateAPIView):
   permission_classes = [AllowAny]
   queryset = Place.objects.all()
   serializer_class = PlaceSerializer
   name = 'places-list'


class PlaceDetail(generics.RetrieveAPIView):
   queryset = Place.objects.all()
   serializer_class = PlaceSerializer
   name = 'places-detail'

class CityList(generics.ListAPIView):
   permission_classes = [IsAuthenticated]
   serializer_class = CitySerializer
   name = 'city-list'

   def get_queryset(self):
      placeID = self.request.query_params.get('placeid')
      if placeID is None:
         raise Http404
      #point_geom  ******
      selectedPlaceGeom = get_object_or_404(Place, pk=placeID).point_geom
      nearestCities = City.objects.annotate(distance=Distance('point_geom', selectedPlaceGeom)).order_by('distance')[:3]
      return nearestCities
   

    

# Create your views here.
#def all_places(request):
   #queryset = Place.objects.all() 
   #geojson = serialize('geojson', queryset, geometry_field='point_geom', srid=3857)
   #return HttpResponse(geojson, content_type='application/json')


#def place_detail(request, pk):
   #data = []
   #try:
      #place = Place.objects.get(pk=pk)
      #data.append(place)
   #except Place.DoesNotExist:
      #pass

   #geojson = serialize('geojson', data, geometry_field= 'point_geom', srid=3857)
   #return HttpResponse(geojson, content_type= 'application/json')

   # SELECT * FROM Place
   # where pk = pk



   #NEW!
class TouristPointViewSet(viewsets.ModelViewSet):
    queryset = TouristPoint.objects.all()
    serializer_class = TouristPointSerializer


class RestaurantViewSet(viewsets.ModelViewSet):
    queryset = Restaurant.objects.all()
    serializer_class = RestaurantSerializer


class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer


class ItineraryThemeViewSet(viewsets.ModelViewSet):
    queryset = ItineraryTheme.objects.all()
    serializer_class = ItineraryThemeSerializer


class ItineraryViewSet(viewsets.ModelViewSet):
    queryset = Itinerary.objects.all()
    serializer_class = ItinerarySerializer


class ItineraryStopViewSet(viewsets.ModelViewSet):
    queryset = ItineraryStop.objects.all()
    serializer_class = ItineraryStopSerializer


class UserTouristPointVisitViewSet(viewsets.ModelViewSet):
    queryset = UserTouristPointVisit.objects.all()
    serializer_class = UserTouristPointVisitSerializer
