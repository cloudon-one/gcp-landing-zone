authorized_networks = [
  "0.0.0.0/0"

]
deletion_protection = true
ssh_keys = {
  "admin" = "ssh-ed25519 AAAAC3Nz..."
  #"user1" = ""
}
enable_iap_tunnel = true
sa_impersonators = [
  "user:user1@fintech.com",
]

proxy_source_ranges = [
  "10.160.0.0/16", # GKE network
  "10.161.0.0/16"  # Data network
]
additional_network_interfaces = [
  {
    vpc_name    = "data-vpc"
    subnet_name = "data-subnet"
  }
]

