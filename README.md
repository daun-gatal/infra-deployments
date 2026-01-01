# Infrastructure Deployments

## Overview

This repository hosts the **Infrastructure as Code (IaC)** for a modern, scalable data platform. It leverages **Terraform** for provisioning and **GitHub Actions** for automated, multi-stage deployment pipelines. The infrastructure is designed to be modular, reliable, and strictly version-controlled, enabling consistent environments from development to production.

The core objective of this project is to deploy and manage a suite of distributed data engineering and observability tools on top of Kubernetes.

## 🏗️ System Architecture

```mermaid
graph TD
    User([User / Developer]) -->|HTTPS| Ingress[Ingress Controller]
    
    subgraph Security
        Ingress --> Keycloak(Keycloak IAM)
        OpenBao(OpenBao Secrets) -.-> Airflow
        OpenBao -.-> Trino
        OpenBao -.-> Superset
    end

    subgraph Data_Platform
        Ingress --> Superset
        Ingress --> Airflow
        
        Superset(Apache Superset) -->|JDBC| Trino(Trino Query Engine)
        Airflow(Apache Airflow) -->|Trigger| Trino
        
        Trino -->|Query| MinIO[(MinIO S3)]
        Trino -->|Query| Kafka(Apache Kafka)
        
        Airflow -->|ETL Jobs| MinIO
    end

    subgraph Storage_and_Metadata
        Postgres[(PostgreSQL DB)]
        
        Superset -->|Metadata| Postgres
        Airflow -->|Metadata| Postgres
        Keycloak -->|Identity Data| Postgres
        Trino -.->|Metastore| Postgres
    end
```

## 🚀 Technology Stack

### Core Infrastructure
-   **IaC**: [Terraform](https://www.terraform.io/) - Used for defining and provisioning all infrastructure resources.
-   **Orchestration**: [Kubernetes](https://kubernetes.io/) - The container orchestration platform hosting all services.
-   **Containerization**: [Docker](https://www.docker.com/) - Used for building custom images and running services.

### CI/CD
-   **GitHub Actions**: Powering the automation pipeline.
    -   **Workflow Dispatch**: Used to trigger specific deployment jobs.
    -   **Terraform Automation**: Custom workflows and scripts to handle `init`, `validate`, `plan`, and `apply` stages safely.

## 🛠️ Deployed Services

This repository manages the deployment of the following key components:

| Service | Category | Description |
| :--- | :--- | :--- |
| **[Apache Airflow](https://airflow.apache.org/)** | Orchestration | Platform to programmatically author, schedule, and monitor workflows. |
| **[Trino](https://trino.io/)** | Query Engine | Distributed SQL query engine for big data analytics. |
| **[Apache Superset](https://superset.apache.org/)** | Visualization | Modern data exploration and visualization platform. |
| **[Keycloak](https://www.keycloak.org/)** | Security | Open Source Identity and Access Management (IAM) for modern applications. |
| **[Apache Kafka](https://kafka.apache.org/)** | Streaming | Distributed event streaming platform for high-performance data pipelines. |
| **[MinIO](https://min.io/)** | Storage | High-performance, S3-compatible object storage. |
| **[OpenBao](https://openbao.org/)** | Security | Secure secret management and data protection (community fork of Vault). |
| **[PostgreSQL](https://www.postgresql.org/)** (via **[CloudNativePG](https://cloudnative-pg.io/)**) | Database | Shared relational database service for application metadata. |

## 📂 Repository Structure

```plaintext
.
├── .github/        # GitHub configuration including workflows
│   └── workflows/  # GitHub Actions workflows
├── deployments/    # Terraform configurations for each service (the heart of the repo)
│   ├── airflow/
│   ├── database/
│   ├── kafka/
│   ├── keycloak/
│   ├── minio/
│   ├── openbao/
│   ├── superset/
│   └── trino/
```

## 🔄 CI/CD Workflow

The deployment pipeline follows a rigorous process to ensure stability:

```mermaid
graph LR
    Push[Git Push / MR] --> GitHub{GitHub Actions}
    
    GitHub -->|Changes in docker/| Build(Build Runner Image)
    
    GitHub -->|Changes in deployments/*| Workflow[Trigger Workflow]
    
    subgraph Terraform_Workflow
        Workflow --> Validate(Terraform Validate)
        Validate --> Plan(Terraform Plan)
        Plan -->|Artifact| Review[Manual Review]
        Review -->|Approval| Apply(Terraform Apply)
    end
```

1.  **Build**: Custom Docker images for the Terraform runner are built (if `docker/Dockerfile` changes).
2.  **Validate**: Terraform configuration is linted and validated for syntax errors.
3.  **Plan**: A speculative execution plan is generated and stored as an artifact. This allows for manual review of proposed changes.
4.  **Execute**: The generated plan is applied to the live environment.

## ✨ Key Features

-   **Modular Design**: Each service is isolated in its own directory under `deployments/`, allowing for independent updates.
-   **GitOps Principles**: All changes are tracked in Git; manual changes to infrastructure are discouraged.
-   **State Management**: Terraform state is managed remotely to ensure consistency and locking.