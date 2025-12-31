terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-dockge"
      project = "infra-deployments"
    }
  }
}
