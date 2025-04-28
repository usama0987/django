from rest_framework import serializers
from .models import Order

class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ['order_id', 'customer_name', 'product_name', 'quantity', 'status']
        read_only_fields = ['order_id', 'status']
