output "alb_dns_name" {
  value = module.container.alb_dns_name
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "ecs_cluster_name" {
  value = module.container.cluster_name
}

output "ecs_service_name" {
  value = module.container.service_name
}

output "ecs_security_group_id" {
  value = module.container.security_group_id
}
