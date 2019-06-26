# Module Gateway

output "gateway_host" {
  value = module.gateway.gateway_host
}

output "gateway_dns" {
  value = module.gateway.gateway_dns
}

output "party_host" {
  value = module.gateway.party_host
}

output "party_dns" {
  value = module.gateway.party_dns
}

output "playfab_auth_host" {
  value = module.gateway.playfab_auth_host
}

output "playfab_auth_dns" {
  value = module.gateway.playfab_auth_dns
}

# Module Analytics

output "analytics_host" {
  value = module.analytics.analytics_host
}

output "analytics_dns" {
  value = module.analytics.analytics_dns
}
