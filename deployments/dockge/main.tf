module "dockge" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/dockge?ref=main"

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

  additional_ports = jsondecode(file("${path.module}/templates/ports.json"))
}

# Add comments here if needed v4
