provider "google" {
  project = var.project
  region  = var.region
  credentials = file(var.credentials_file) 
}

resource "null_resource" "see_ssh" {
  provisioner "local-exec" {
    command = "ls -la ~/.ssh; cat ~/.ssh/id_rsa.pub"
  }
}

resource "null_resource" "add_host_key" {
  provisioner "local-exec" {
    command = "ssh-keyscan github.com >> ~/.ssh/known_hosts"
  }
}

resource "null_resource" "git_clone_products" {
  provisioner "local-exec" {
    command = "git clone git@github.com:dotcomrow/products-terraform-workspace.git"
  }
}

resource "null_resource" "git_clone_cart" {
  provisioner "local-exec" {
    command = "git clone git@github.com:dotcomrow/cart-terraform-workspace.git"
  }
}

resource "null_resource" "git_clone_orders" {
  provisioner "local-exec" {
    command = "git clone git@github.com:dotcomrow/orders-terraform-workspace.git"
  }
}

# module "products" {
#   source = "./modules/projects"
#   project_name = "products-domain"
#   gcp_org_id = var.gcp_org_id
#   # apis = var.apis
#   project_module = "git@github.com:dotcomrow/products-terraform-workspace.git//terraform"
# }

# module "carts" {
#   source = "./modules/projects"
#   project_name = "carts-domain"
#   gcp_org_id = var.gcp_org_id
#   # apis = var.apis
#   project_module = "git@github.com:dotcomrow/cart-terraform-workspace.git//terraform"
# }

# module "orders" {
#   source = "./modules/projects"
#   project_name = "orders-domain"
#   gcp_org_id = var.gcp_org_id
#   # apis = var.apis
#   project_module = "git@github.com:dotcomrow/orders-terraform-workspace.git//terraform"
# }