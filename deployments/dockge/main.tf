module "dockge" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/dockge?ref=main"

  namespace    = "dockge"
  service_port = 80

  tailscale_funnel = true
  
  tailscale_app_expose = true
  additional_ports = []
}

# Add comments here if needed v1
