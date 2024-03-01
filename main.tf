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