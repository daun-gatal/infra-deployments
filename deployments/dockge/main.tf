module "dockge" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/dockge?ref=main"

  namespace    = "dockge"
  service_port = 80

  tailscale_funnel = false
  tailscale_expose = true
  
  tailscale_app_expose = true

  resources = {
    dind = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "6000m"
        memory = "12Gi"
      }
    }
  }

  additional_ports = [
    {
      name = "port-8080"
      port = 8080
    },
    {
      name = "port-5432"
      port = 5432
    }
  ]
}

# Add comments here if needed v3
