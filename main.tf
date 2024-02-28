// Create random ID for resource group, environment, log analytics workspace and container name
resource "random_id" "rg_name" {
  byte_length = 8
}

resource "random_id" "env_name" {
  byte_length = 8
}

resource "random_id" "law_name" {
  byte_length = 8
}

resource "random_id" "container_name" {
  byte_length = 4
}


// Azure resource group
resource "azurerm_resource_group" "coloursdemo-rg" {
  name     = "rg-containerapps-${var.resource_name}-${random_id.rg_name.hex}"
  location = var.location
}


// Log Analytics workspace for the container apps environment
resource "azurerm_log_analytics_workspace" "coloursdemo-la" {
  name                = "law-${var.resource_name}-${random_id.law_name.hex}"
  location            = var.location
  resource_group_name = azurerm_resource_group.coloursdemo-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


// Azure Container Apps environment
resource "azurerm_container_app_environment" "coloursdemo-cae" {
  name                       = "caenv-${var.resource_name}-${random_id.env_name.hex}"
  resource_group_name        = azurerm_resource_group.coloursdemo-rg.name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.coloursdemo-la.id
}

// Container App for the web front end
resource "azurerm_container_app" "coloursdemo-ca-web" {
  name                         = "ca-${var.resource_name}-${random_id.container_name.hex}-web"
  resource_group_name          = azurerm_resource_group.coloursdemo-rg.name
  container_app_environment_id = azurerm_container_app_environment.coloursdemo-cae.id
  revision_mode                = "Single"

  template {
    container {
      name   = "examplecontainerapp"
      image  = "ghcr.io/markharrison/coloursweb:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas    = 0
    max_replicas    = 3
    revision_suffix = "webv1"
  }


  // Ingress where external access is allowed
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

}



// Container App for the backend API
resource "azurerm_container_app" "coloursdemo-ca-api" {
  name                         = "ca-${var.resource_name}-${random_id.container_name.hex}-api"
  resource_group_name          = azurerm_resource_group.coloursdemo-rg.name
  container_app_environment_id = azurerm_container_app_environment.coloursdemo-cae.id
  revision_mode                = "Multiple"

  template {
    container {
      name   = "examplecontainerapp"
      image  = "ghcr.io/markharrison/coloursapi:blue"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas    = 0
    max_replicas    = 3
    revision_suffix = "bluev1"
  }


  // Ingress where external access is not allowed
  ingress {
    allow_insecure_connections = true
    external_enabled           = false
    target_port                = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

}

