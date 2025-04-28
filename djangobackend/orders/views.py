import uuid
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Order
from .serializers import OrderSerializer
import boto3
import json
from django.conf import settings

# Initialize AWS services
dynamodb = boto3.resource('dynamodb', region_name=settings.AWS_REGION)
sns = boto3.client('sns', region_name=settings.AWS_REGION)
table = dynamodb.Table(settings.DYNAMODB_TABLE_NAME)

class OrderCreateView(APIView):
    """
    API endpoint for creating new orders
    """
    def post(self, request):
        serializer = OrderSerializer(data=request.data)
        if serializer.is_valid():
            order_data = serializer.validated_data
            order_id = str(uuid.uuid4())

            item = {
                'order_id': order_id,
                'customer_name': order_data['customer_name'],
                'product_name': order_data['product_name'],
                'quantity': order_data['quantity'],
                'status': 'Pending'
            }

            try:
                # Save to DynamoDB
                table.put_item(Item=item)

                # Prepare and publish SNS message with enhanced format
                sns_message = {
                    'order_id': order_id,
                    'event_type': 'order_created',
                    'customer_name': order_data['customer_name'],
                    'product_name': order_data['product_name'],
                    'quantity': order_data['quantity'],
                    'status': 'Pending'
                }

                sns.publish(
                    TopicArn=settings.SNS_TOPIC_ARN,
                    Message=json.dumps(sns_message),
                    MessageAttributes={
                        'event_type': {
                            'DataType': 'String',
                            'StringValue': 'order_created'
                        }
                    }
                )

                return Response(item, status=status.HTTP_201_CREATED)
            
            except Exception as e:
                # Log the error for debugging
                print(f"Error processing order: {str(e)}")
                return Response(
                    {'error': 'Failed to process order'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class OrderRetrieveView(APIView):
    """
    API endpoint for retrieving order details
    """
    def get(self, request, order_id):
        try:
            response = table.get_item(
                Key={'order_id': str(order_id)}
            )
            if 'Item' not in response:
                return Response(
                    {'error': 'Order not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            return Response(response['Item'], status=status.HTTP_200_OK)
        
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
