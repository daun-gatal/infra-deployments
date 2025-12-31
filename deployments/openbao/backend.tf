terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-openbao"
      project = "infra-deployments"
    }
  }
}
