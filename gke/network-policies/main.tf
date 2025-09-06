terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  region = "us-central1"
}

provider "kubernetes" {
  alias       = "prod"
  config_path = "~/.kube/config"
}


module "default_deny_policies" {
  source = "./modules/default-deny"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "backend_network_policies" {
  source = "./modules/backend"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "frontend_network_policies" {
  source = "./modules/frontend"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "api_network_policies" {
  source = "./modules/api"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "monitoring_network_policies" {
  source = "./modules/monitoring"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "database_network_policies" {
  source = "./modules/database"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "production_network_policies" {
  source = "./modules/production"
  providers = {
    kubernetes = kubernetes.prod
  }
}

module "default_network_policies" {
  source = "./modules/default"
  providers = {
    kubernetes = kubernetes.prod
  }
} 