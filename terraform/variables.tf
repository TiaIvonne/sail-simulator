# Variables for Boat Racing Lambda Architecture
# Keep sensitive values in terraform.tfvars (which should be gitignored)

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "boat-racing"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "sql_admin_password" {
  description = "Password for SQL Server admin (keep this secure!)"
  type        = string
  sensitive   = true
  # No default - must be provided in terraform.tfvars
}

variable "sql_admin_username" {
  description = "Username for SQL Server admin"
  type        = string
  default     = "sqladmin"
}

# Optional: Add your own IP for SQL firewall access
variable "your_ip_address" {
  description = "Your IP address for SQL Server firewall (optional)"
  type        = string
  default     = null
}

# Azure Authentication is handled via environment variables
# No variables needed - see main.tf for required environment variables