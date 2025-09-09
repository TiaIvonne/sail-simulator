# Simple Terraform configuration for Boat Racing Lambda Architecture
# Perfect for student projects - everything in one file!

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  # Use environment variables for authentication (no browser needed)
  # Set these environment variables before running terraform:
  # export ARM_SUBSCRIPTION_ID="your-subscription-id"
  # export ARM_CLIENT_ID="your-client-id" 
  # export ARM_CLIENT_SECRET="your-client-secret"
  # export ARM_TENANT_ID="your-tenant-id"
}

# Variables are now in variables.tf
# Sensitive values are in terraform.tfvars (gitignored)

# Generate random suffix for unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group - everything goes here
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${random_string.suffix.result}"
  location = var.location
}

# Event Hub Namespace
resource "azurerm_eventhub_namespace" "main" {
  name                = "${var.project_name}-eventhub-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 1
}

# Event Hub
resource "azurerm_eventhub" "main" {
  name                = "telemetry"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name
  partition_count     = 2
  message_retention   = 1
}

# Event Hub Authorization Rule
resource "azurerm_eventhub_authorization_rule" "main" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = azurerm_resource_group.main.name
  listen              = true
  send                = true
  manage              = true
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-sql-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "boat-racing-db"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"
}

# SQL Server Firewall Rules
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "grafana_cloud" {
  name             = "GrafanaCloud"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "3.125.31.111"
  end_ip_address   = "3.125.31.111"
}

# Optional: Allow your personal IP for database access
resource "azurerm_mssql_firewall_rule" "your_ip" {
  count            = var.your_ip_address != null ? 1 : 0
  name             = "YourPersonalIP"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.your_ip_address
  end_ip_address   = var.your_ip_address
}

# Storage Account removed - not needed for basic Stream Analytics job

# Stream Analytics Job
resource "azurerm_stream_analytics_job" "main" {
  name                                     = "${var.project_name}-asa-${random_string.suffix.result}"
  resource_group_name                      = azurerm_resource_group.main.name
  location                                 = azurerm_resource_group.main.location
  compatibility_level                      = "1.2"
  data_locale                             = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy              = "Adjust"
  output_error_policy                     = "Drop"
  streaming_units                         = 1

  transformation_query = <<QUERY
SELECT
    TRY_CAST(boat as bigint) as boat_id,
    TRY_CAST(latitude as float) as latitude,
    TRY_CAST(longitude as float) as longitude,
    TRY_CAST(heading as float) as heading,
    TRY_CAST(speed as float) as speed,
    TRY_CAST(EventProcessedUtcTime as datetime) as event_time,
    TRY_CAST(EventEnqueuedUtcTime as datetime) as enqueued_time
INTO
    [boat-telemetry-sql]
FROM
    [telemetry-input]
WHERE 
    latitude != -10000.0 
    and longitude != -10000.0
    and latitude >= -90.0 and latitude <= 90.0 
    and longitude >= -180.0 and longitude <= 180.0 
    and latitude is not null 
    and longitude is not null
    and boat is not null
    and speed >= 0.0 
    and speed <= 50.0
    and EventProcessedUtcTime is not null 
    and EventEnqueuedUtcTime is not null
QUERY
}

# Stream Analytics Input (Event Hub)
resource "azurerm_stream_analytics_stream_input_eventhub" "main" {
  name                         = "telemetry-input"
  stream_analytics_job_name    = azurerm_stream_analytics_job.main.name
  resource_group_name          = azurerm_resource_group.main.name
  eventhub_consumer_group_name = "$Default"
  eventhub_name                = azurerm_eventhub.main.name
  servicebus_namespace         = azurerm_eventhub_namespace.main.name
  shared_access_policy_key     = azurerm_eventhub_authorization_rule.main.primary_key
  shared_access_policy_name    = azurerm_eventhub_authorization_rule.main.name

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

# Stream Analytics Output (SQL Database)
resource "azurerm_stream_analytics_output_mssql" "main" {
  name                      = "boat-telemetry-sql"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = azurerm_resource_group.main.name
  server                    = azurerm_mssql_server.main.fully_qualified_domain_name
  database                  = azurerm_mssql_database.main.name
  user                      = azurerm_mssql_server.main.administrator_login
  password                  = var.sql_admin_password
  table                     = "boat_telemetry"
}

# Outputs - Important connection details
output "event_hub_connection_string" {
  description = "Event Hub connection string for your Python simulator"
  value       = azurerm_eventhub_authorization_rule.main.primary_connection_string
  sensitive   = true
}

output "event_hub_name" {
  description = "Event Hub name"
  value       = azurerm_eventhub.main.name
}

output "sql_server_name" {
  description = "SQL Server name for Grafana"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "SQL Database name"
  value       = azurerm_mssql_database.main.name
}

output "sql_username" {
 
 
  description = "SQL admin username"
  value       = azurerm_mssql_server.main.administrator_login
}

output "deployment_summary" {
  description = "Quick summary of what was created"
  value = {
    resource_group    = azurerm_resource_group.main.name
    eventhub         = "${azurerm_eventhub_namespace.main.name}/${azurerm_eventhub.main.name}"
    sql_server       = azurerm_mssql_server.main.fully_qualified_domain_name
    sql_database     = azurerm_mssql_database.main.name
    stream_analytics = azurerm_stream_analytics_job.main.name
  }
}