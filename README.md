
# Serverless E-Commerce Order Processing System

## Overview

This project is a **serverless, event-driven e-commerce order processing system** built on AWS, featuring:

- ✅ Django REST API (ECS Fargate)
- ✅ AWS Lambda for asynchronous order processing
- ✅ DynamoDB for NoSQL storage
- ✅ SNS/SQS for event-driven messaging
- ✅ Terraform for Infrastructure as Code (IaC)

The Django application was containerized using a multi-stage Dockerfile, pushed to **Amazon ECR**, and deployed via **ECS Fargate**. Health checks confirm successful startup on port `8000`.

---

## Architecture

### Business Flow
1. **Order Creation** → API → DynamoDB
2. **Order Processing** → SQS → Lambda → External APIs (Payment/Inventory)
3. **Status Updates** → DynamoDB + SNS Notifications

### Core Components

#### 1. Django REST API (ECS Fargate)
- **Endpoints:**
  - `POST /orders/` → Create an order
  - `GET /orders/{order_id}/` → Retrieve an order
- **Tech Stack:**
  - Python 3.9 + Django + Django REST Framework
  - Dockerized deployment

#### 2. AWS Lambda (Order Processor)
- Processes orders from SQS
- Simulates Payment and Inventory APIs
- Retries failed orders (3 attempts)
- Updates DynamoDB (`status: Completed/Failed`)

#### 3. Event-Driven Messaging (SNS/SQS)
- **Topics:**
  - `dev-order-events` (New orders)
  - `dev-order-completed` (Processed orders)
- **Queues:**
  - `dev-order-processing` (Main queue)
  - `dev-order-dlq` (Dead Letter Queue)

---

## Infrastructure as Code (Terraform)

**Directory Structure:**
```
terraform/
├── modules/
│   ├── api_gateway/    # API Gateway config
│   ├── container/      # ECS + ALB
│   ├── lambda/         # Lambda function
│   ├── messaging/      # SNS + SQS
│   └── networking/     # VPC + Subnets
└── environments/
    └── dev/            # Development environment config
```

> To get the Application Load Balancer DNS after deployment:
> ```bash
> ALB_DNS=$(terraform output -raw alb_dns_name)
> ```

---

## How to Create an Order

**Example `curl` Command:**

```bash
curl -X POST "http://${ALB_DNS}/orders/" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "Test Customer",
    "product_name": "Test Product",
    "quantity": 1
  }'
```

---

## Checking Order Status in DynamoDB

**Example AWS CLI Command:**

```bash
aws dynamodb get-item \
  --table-name dev-orders \
  --key "{\"order_id\":{\"S\":\"$ORDER_ID\"}}" \
  --region us-west-2
```

**Sample Output:**
```json
{
    "Item": {
        "quantity": {"N": "1"},
        "order_id": {"S": "ff42b3bc-f803-415d-9f90-d07365af9064"},
        "product_name": {"S": "Test Product"},
        "customer_name": {"S": "Test Customer"},
        "status": {"S": "Completed"}
    }
}
```

---

## Lambda Processing Logs

You can tail the Lambda logs:

```bash
aws logs tail /aws/lambda/dev-order-processor-v2 --follow --region us-west-2
```

---

## Conclusion

This serverless e-commerce system provides:

- ✅ **Scalability** — Handles thousands of orders
- ✅ **Reliability** — SQS retries + Dead Letter Queue
- ✅ **Cost Efficiency** — Pay-per-use model

---

## Next Steps

- Setup CI/CD pipeline
- Add automated tests
