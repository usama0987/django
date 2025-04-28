
import json
import boto3
import time
import random
import os
import logging
from decimal import Decimal
from botocore.exceptions import ClientError

# Custom JSON encoder to handle Decimal
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
REGION = os.environ.get('REGION', 'us-west-2')
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE', 'dev-orders')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

dynamodb = boto3.resource('dynamodb', region_name=REGION)
sns = boto3.client('sns', region_name=REGION)
table = dynamodb.Table(DYNAMODB_TABLE)

def simulate_api_call(order_id, api_type):
    """Simulate an external API call with 20% failure rate"""
    logger.info(f"Simulating {api_type} API call for order {order_id}")
    if random.random() < 0.2:
        logger.error(f"{api_type} API call failed for order {order_id}")
        raise Exception(f"{api_type} API call failed")
    time.sleep(2)
    return True

def update_order_status(order_id, status):
    """Update order status in DynamoDB"""
    try:
        logger.info(f"Updating order {order_id} status to {status}")
        table.update_item(
            Key={'order_id': order_id},
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': status}
        )
        return True
    except Exception as e:
        logger.error(f"Error updating order status: {str(e)}")
        raise

def process_order(order_id):
    """Process a single order"""
    try:
        # Get order from DynamoDB
        logger.info(f"Fetching order {order_id} from DynamoDB")
        response = table.get_item(Key={'order_id': order_id})

        if 'Item' not in response:
            logger.error(f"Order {order_id} not found")
            return False

        order = response['Item']
        logger.info(f"Found order: {json.dumps(order, cls=DecimalEncoder)}")

        # Update to Processing
        update_order_status(order_id, 'Processing')
        logger.info(f"Updated order {order_id} to Processing")

        try:
            # Simulate payment API
            simulate_api_call(order_id, "Payment")
            logger.info(f"Payment processed for order {order_id}")

            # Simulate inventory API
            simulate_api_call(order_id, "Inventory")
            logger.info(f"Inventory checked for order {order_id}")

            # Update to Completed
            update_order_status(order_id, 'Completed')
            logger.info(f"Updated order {order_id} to Completed")

            # Publish completion event
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps({
                    'order_id': order_id,
                    'status': 'Completed',
                    'customer_name': order.get('customer_name'),
                    'product_name': order.get('product_name'),
                    'quantity': float(order.get('quantity', 0))  # Convert Decimal to float
                }, cls=DecimalEncoder)
            )
            logger.info(f"Published completion event for order {order_id}")

            return True

        except Exception as e:
            logger.error(f"Processing failed for order {order_id}: {str(e)}")
            update_order_status(order_id, 'Failed')
            return False

    except Exception as e:
        logger.error(f"Error processing order {order_id}: {str(e)}")
        try:
            update_order_status(order_id, 'Failed')
        except Exception as update_error:
            logger.error(f"Error updating order status to Failed: {str(update_error)}")
        return False

def handler(event, context):
    """Lambda handler"""
    logger.info(f"Processing event: {json.dumps(event)}")

    for record in event['Records']:
        try:
            # Parse SNS message from SQS
            body = json.loads(record['body'])
            message = json.loads(body.get('Message', '{}'))

            order_id = message.get('order_id')
            if not order_id:
                logger.error("No order_id found in message")
                continue

            logger.info(f"Processing order: {order_id}")
            retries = 3

            while retries > 0:
                try:
                    if process_order(order_id):
                        logger.info(f"Successfully processed order {order_id}")
                        break
                    retries -= 1
                    if retries > 0:
                        wait_time = 2 ** (3 - retries)
                        logger.info(f"Retrying order {order_id} in {wait_time} seconds")
                        time.sleep(wait_time)
                except Exception as e:
                    logger.error(f"Error in retry loop for order {order_id}: {str(e)}")
                    retries -= 1
                    if retries == 0:
                        logger.error(f"Max retries reached for order {order_id}")

        except Exception as e:
            logger.error(f"Error processing record: {str(e)}")

    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }
