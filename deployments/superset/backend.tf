terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-superset"
    }
  }
}
