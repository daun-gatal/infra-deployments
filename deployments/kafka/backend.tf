terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-kafka"
      project = "infra-deployments"
    }
  }
}
