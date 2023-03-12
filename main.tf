terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.45.0"
    }
  }
}

# Configure Provider
provider "azurerm" {
  # Configuration options
  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  features {}
}

# Declaring local variables to be used within main.tf
locals {
  resource_group = "webapp-app"
  location = "North Europe"
}

# Create a Resource Group
resource "azurerm_resource_group" "webapp_app" {
    name = local.resource_group
    location = local.location
}

# Create Web App Service Plan
resource "azurerm_service_plan" "webapp_service_plan" {
  name                = "webapp-service-plan"
  resource_group_name = local.resource_group
  location            = local.location
  sku_name            = "F1"
  os_type             = "Windows"
  depends_on = [
    azurerm_resource_group.webapp_app
  ]
}

# Create Web App Service
resource "azurerm_windows_web_app" "webapp_service" {
  name                = "webapp-service584629"
  resource_group_name = local.resource_group
  location            = local.location
  service_plan_id     = azurerm_service_plan.webapp_service_plan.id

  site_config {
    always_on  = false
  }
  depends_on = [
    azurerm_service_plan.webapp_service_plan
  ]
}

# Create Source Control Resource for Web App
resource "azurerm_app_service_source_control" "dotnet_app" {
  app_id   = azurerm_windows_web_app.webapp_service.id
  repo_url = "https://github.com/cloudxeus/ProductApp.git"
  branch   = "master"
  depends_on = [
    azurerm_windows_web_app.webapp_service
  ]
}

# Create an SQL DB Server
resource "azurerm_mssql_server" "webapp_db_server" {
  name                         = "webapp-db450870518"
  resource_group_name          = local.resource_group
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "sqlAdmin"
  administrator_login_password = "AdminPa$$w0rd"
}

# Create SQL DB
resource "azurerm_mssql_database" "webapp_db" {
  name                = "webapp-db"
  server_id           = azurerm_mssql_server.webapp_db_server.id
  depends_on = [
    azurerm_mssql_server.webapp_db_server
  ]
}

# Create SQL Firewall Rule
resource "azurerm_mssql_firewall_rule" "webapp_firewall" {
  name             = "webapp-db-firewall-1"
  server_id        = azurerm_mssql_server.webapp_db_server.id
  start_ip_address = "105.112.120.104"
  end_ip_address   = "105.112.120.104"
  depends_on = [
    azurerm_mssql_database.webapp_db
  ]
}

# Create SQL Firewall Rule 2
resource "azurerm_mssql_firewall_rule" "webapp_firewall_rule_azure_services" {
  name             = "webapp-db-firewall-2"
  server_id        = azurerm_mssql_server.webapp_db_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
  depends_on = [
    azurerm_mssql_database.webapp_db
  ]
}


# Create the command for sql
resource "null_resource" "database_setup" {
    provisioner "local-exec" {
        command = "sqlcmd -S webapp-db450870518.database.windows.net -U sqladmin -P AdminPa$$w0rd -d webapp-db -i init.sql"    
    }  
    depends_on = [
      azurerm_mssql_server.webapp_db_server 
    ]
}