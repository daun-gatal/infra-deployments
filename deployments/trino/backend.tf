terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-trino"
      project = "infra-deployments"
    }
  }
}
