                                                        Serverless E-Commerce Order Processing System
System Overview:

The Django application was containerized using a multi-stage Dockerfile, then pushed to Amazon ECR. The image (615299759671.dkr.ecr.us-west-2.amazonaws.com/ecomerce:latest) was deployed via ECS Fargate, with health checks confirming successful startup on port 8000.
A serverless, event-driven e-commerce order processing system built on AWS, featuring:
✔ Django REST API (ECS Fargate)
✔ AWS Lambda for async order processing
✔ DynamoDB for NoSQL storage
✔ SNS/SQS for event-driven messaging
✔ Terraform for IaC (Infrastructure as Code)

Business Flow:
1.	Order Creation → API → DynamoDB
2.	Order Processing → SQS → Lambda → External APIs (P 
3.	ayment/Inventory)
4.	Status Updates → DynamoDB + SNS Notifications

Core Components
1. Django REST API (ECS Fargate)
•	Endpoints:
o	POST /orders/ → Create order
o	GET /orders/{order_id}/ → Retrieve order
•	Tech Stack:
o	Python 3.9 + Django + DRF
o	Dockerized deployment

2. AWS Lambda (Order Processor)
•	Features:
o	Processes orders from SQS
o	Simulates Payment & Inventory APIs
o	Retries failed orders (3 attempts)
o	Updates DynamoDB (status: Completed/Failed)
Event-Driven Messaging (SNS/SQS)
•	Topics:
o	dev-order-events (New orders)
o	dev-order-completed (Processed orders)
•	Queues:
o	dev-order-processing (Main queue)
o	dev-order-dlq (Dead Letter Queue)

Infrastructure as Code (Terraform)
Modules Structure
terraform/
├── modules/
│   ├── api_gateway/   # API Gateway config
│   ├── container/     # ECS + ALB
│   ├── lambda/        # Lambda function
│   ├── messaging/     # SNS + SQS
│   └── networking/    # VPC + Subnets
└── environments/
    └── dev/          # Dev environment config




  ALB_DNS=$(terraform output -raw alb_dns_name)

The command ALB_DNS=$(terraform output -raw alb_dns_name) is used to capture the DNS name of an Application Load Balancer (ALB) from Terraform's output and store it in a shell variable (ALB_DNS) for later use in scripts or commands.


Order Creation

curl -X POST "http://${ALB_DNS}/orders/" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "Test Customer",
    "product_name": "Test Product",
    "quantity": 1
  }'



The result after process:

aws dynamodb get-item \
  --table-name dev-orders \
  --key "{\"order_id\":{\"S\":\"$ORDER_ID\"}}" \
  --region us-west-2
{
    "Item": {
        "quantity": {
            "N": "1"
        },
        "order_id": {
            "S": "ff42b3bc-f803-415d-9f90-d07365af9064"
        },
        "product_name": {
            "S": "Test Product"
        },
        "customer_name": {
            "S": "Test Customer"
        },
        "status": {
            "S": "Completed"
        }
    }
}



Lambda Processing Logs
You can get the logs through this command :
aws logs tail /aws/lambda/dev-order-processor-v2 --follow --region us-west-2

As you can see in the screenshot:
 

 Conclusion
This serverless e-commerce system provides:
✅ Scalability (Handles 1000s of orders)
✅ Reliability (SQS retries + DLQ)
✅ Cost Efficiency (Pay-per-use model)


Next Steps:
•	Set up CI/CD pipeline
•	Add automated testing
__________________________________________________________________
