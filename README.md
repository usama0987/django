# Serverless E-Commerce System
terra/
├── environments/
│   └── dev/
│       ├── main.tf       # Main configuration for the dev environment
│       ├── output.tf     # Output values for dev environment
├── modules/
│   ├── api_gateway/     # API Gateway configuration
│   │   └── main.tf      # Main configuration for API Gateway
│   ├── container/       # ECS and ECR resources
│   │   └── main.tf      # Main configuration for container resources
│   ├── lambda/          # Lambda function (e.g., order processor)
│   │   ├── main.tf      # Main configuration for Lambda
│   │   └── function/    # Lambda function files
│   │       ├── order_processor.py
│   │       └── order_processor.zip
│   ├── messaging/       # SNS topics and SQS queues
│   │   └── main.tf      # Main configuration for messaging resources
│   ├── networking/      # VPC, subnets, security groups
│   │   └── main.tf      # Main configuration for networking resources
│   └── storage/         # Storage resources
│       └── main.tf      # Main configuration for storage resources
