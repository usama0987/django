from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView

urlpatterns = [
    # Admin panel
    path('admin/', admin.site.urls),
    
    # Orders endpoints
    path('orders/', include('orders.urls')),
    
    # Root redirect (permanent 301)
    path('', RedirectView.as_view(url='/orders/', permanent=True)),
]
