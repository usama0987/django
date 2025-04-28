
provider "aws" {
  region = "us-west-2"
  access_key = "********************"
  secret_key = "********************************"
}

locals {
  environment = "dev"
}

module "networking" {
  source = "../../modules/networking"
}

module "messaging" {
  source      = "../../modules/messaging"
  environment = local.environment
}

module "lambda" {
  source              = "../../modules/lambda"
  environment         = local.environment
  sqs_queue_arn       = module.messaging.order_processing_queue_arn
  sns_topic_arn       = module.messaging.order_completed_topic_arn
}

module "container" {
  source             = "../../modules/container"
  environment        = local.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_ids
  ecr_repository_url = "615299759671.dkr.ecr.us-west-2.amazonaws.com/ecomerce"
}

module "api_gateway" {
  source            = "../../modules/api_gateway"
  environment       = local.environment
  vpc_id            = module.networking.vpc_id
  alb_listener_arn  = module.container.alb_listener_arn
}
