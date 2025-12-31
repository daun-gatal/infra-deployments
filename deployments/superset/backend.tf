terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-superset"
      project = "infra-deployments"
    }
  }
}
