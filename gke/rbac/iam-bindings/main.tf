provider "google" {
  region = "us-central1"
}

provider "kubernetes" {
  alias = "prod"
}


module "kubernetes_prod" {
  source    = "./submodules/kubernetes-prod-binding"
  providers = { kubernetes = kubernetes.prod }
}