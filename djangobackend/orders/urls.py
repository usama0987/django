from django.urls import path
from .views import OrderCreateView, OrderRetrieveView

urlpatterns = [
    path('', OrderCreateView.as_view(), name='order-create-list'),
    path('<uuid:order_id>/', OrderRetrieveView.as_view(), name='order-detail'),
]
