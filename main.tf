terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-labs/snowflake"
      version = "~> 0.76"
    }
  }
}

provider "snowflake" {
  role = "SYSADMIN"
}

resource "snowflake_database" "db" {
  name    = "db_example"
  comment = "Example database"
}

resource "snowflake_warehouse" "warehouse" {
  name           = "wh_example"
  comment        = "Example warehouse"
  warehouse_size = "X-SMALL"
  auto_suspend   = 60
}

provider "snowflake" {
  role  = "SECURITYADMIN"
  alias = "security_admin"
}

resource "snowflake_role" "role" {
  provider = snowflake.security_admin
  name     = "TF_JASM_DEMO"
}

resource "snowflake_grant_privileges_to_role" "database_grant" {
  provider   = snowflake.security_admin
  privileges = ["USAGE"]
  role_name  = snowflake_role.role.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.db.name
  }
}

resource "snowflake_schema" "schema" {
  database = snowflake_database.db.name
  provider = snowflake
  name = "TF_DEMO_SCHEMA"
  is_managed = false
}

resource "snowflake_grant_privileges_to_role" "schema_grant" {
  provider   = snowflake.security_admin
  privileges = ["USAGE"]
  role_name  = snowflake_role.role.name
  on_schema {
    schema_name = "\"${snowflake_database.db.name}\".\"${snowflake_schema.schema.name}\""
  }
}

resource "snowflake_grant_privileges_to_role" "warehouse_grant" {
  provider   = snowflake.security_admin
  privileges = ["USAGE"]
  role_name  = snowflake_role.role.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.warehouse.name
  }
}

resource "tls_private_key" "svc_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "snowflake_user" "svc_user" {
  provider          = snowflake.security_admin
  name              = "tf_demo_user"
  default_warehouse = snowflake_warehouse.warehouse.name
  default_role      = snowflake_role.role.name
  default_namespace = "${snowflake_database.db.name}.${snowflake_schema.schema.name}"
  rsa_public_key    = substr(tls_private_key.svc_key.public_key_pem, 27, 398)
}

resource "snowflake_grant_privileges_to_role" "user_grant" {
  provider   = snowflake.security_admin
  privileges = ["MONITOR"]
  role_name  = snowflake_role.role.name
  on_account_object {
    object_type = "USER"
    object_name = snowflake_user.svc_user.name
  }
}

resource "snowflake_role_grants" "grants" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.role.name
  users     = [snowflake_user.svc_user.name]
}