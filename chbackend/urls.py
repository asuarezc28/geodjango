from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from rest_framework.urlpatterns import format_suffix_patterns

# Router para los ViewSets
router = DefaultRouter()
router.register(r'tourist-points', views.TouristPointViewSet)
router.register(r'restaurants', views.RestaurantViewSet)
router.register(r'events', views.EventViewSet)
router.register(r'itinerary-themes', views.ItineraryThemeViewSet)
router.register(r'itineraries', views.ItineraryViewSet)
router.register(r'itinerary-stops', views.ItineraryStopViewSet)
router.register(r'user-visits', views.UserTouristPointVisitViewSet)

# Vistas personalizadas
custom_urlpatterns = [
    path('categories/', views.CategoryList.as_view(), name=views.CategoryList.name),
    path('categories/<int:pk>/', views.CategoryDetail.as_view(), name=views.CategoryDetail.name),
    path('places/', views.PlaceList.as_view(), name=views.PlaceList.name),
    path('places/<int:pk>/', views.PlaceDetail.as_view(), name=views.PlaceDetail.name),
    path('cities/', views.CityList.as_view(), name=views.CityList.name),
    path('api-auth/', include('rest_framework.urls')),
]

# Combinamos todo
urlpatterns = format_suffix_patterns(custom_urlpatterns) + [
    path('api/', include(router.urls)),
]
