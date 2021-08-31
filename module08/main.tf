

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "3eccf495-e528-4a78-8780-99fb57bd12d4"
  client_id       = "b32d2db1-0a6d-4b9f-8c80-3e16aeab474a"
  client_secret   = "23.mkHL3S_Z_Q53657327nHUv8HSuVICcUzsYh"
  tenant_id       = "bd73ab09-cb80-4e0a-8c43-7258720d148d"

  features {}
}
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Name = var.environment_name

  }
}

#AzureSQLDB

resource "azurerm_sql_server" "Sqlutt" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  tags = {
    Name = var.environment_name
  }
}

resource "azurerm_storage_account" "storageutt05" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_sql_database" "uttdatabase" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  server_name         = azurerm_sql_server.Sqlutt.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.storageutt05.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.storageutt05.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }



  tags = {
    Name = var.environment_name
  }
}


###datalake

resource "azurerm_data_lake_store" "azuredatalake" {
  name                = var.datalake_store_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_data_lake_analytics_account" "datalakeacc" {
  name                = var.datalake_acc_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  default_store_account_name = azurerm_data_lake_store.azuredatalake.name
}

##datafactory


resource "azurerm_data_factory" "azuredatafactory" {
  name                = var.datafactory_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

###functionapp

resource "azurerm_storage_account" "storeacctwo" {
  name                     = var.functionapp_storageacc_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = var.appservice_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "uttfunctionapp" {
  name                       = var.functionapp_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.appserviceplan.id
  storage_account_name       = azurerm_storage_account.storeacctwo.name
  storage_account_access_key = azurerm_storage_account.storeacctwo.primary_access_key
}

####synapse  analytics

resource "azurerm_storage_account" "synapstorrageacc" {
  name                     = var.synapseanalytics_storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapsedatalakestorage" {
  name               = var.synanal_storage_datalake
  storage_account_id = azurerm_storage_account.synapstorrageacc.id
}

resource "azurerm_synapse_workspace" "synworkspace" {
  name                                 = var.synanalworkspace_name
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapsedatalakestorage.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "H@Sh1CoR3!"
}

resource "azurerm_synapse_firewall_rule" "synapsefirewall" {
  name                 = var.azurerm_synapse_firewall_rule_name
  synapse_workspace_id = azurerm_synapse_workspace.synworkspace.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

data "azurerm_client_config" "current" {}

resource "azurerm_synapse_role_assignment" "azurermsynapseroleassignment" {
  synapse_workspace_id = azurerm_synapse_workspace.synworkspace.id
  role_name            = "Synapse SQL Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [azurerm_synapse_firewall_rule.synapsefirewall]
}


#####IOTHUB

resource "azurerm_storage_account" "iotstorageacc" {
  name                     = var.iotstorageacc_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "iotcont" {
  name                  = var.iotcontainer_name
  storage_account_name  = azurerm_storage_account.iotstorageacc.name
  container_access_type = "private"
}

resource "azurerm_eventhub_namespace" "eventhub" {
  name                = var.eventhub_namespace_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
}

resource "azurerm_eventhub" "venthubmple" {
  name                = var.eventhub_name
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "example" {
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.venthubmple.name
  name                = "acctest"
  send                = true
}

resource "azurerm_iothub" "example" {
  name                = var.azurerm_iothub_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "S1"
    capacity = "1"
  }

  endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.iotstorageacc.primary_blob_connection_string
    name                       = "export"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = azurerm_storage_container.iotcont.name
    encoding                   = "Avro"
    file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  }

  endpoint {
    type              = "AzureIotHub.EventHub"
    connection_string = azurerm_eventhub_authorization_rule.example.primary_connection_string
    name              = "export2"
  }

  route {
    name           = "export"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["export"]
    enabled        = true
  }

  route {
    name           = "export2"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["export2"]
    enabled        = true
  }

  enrichment {
    key            = "tenant"
    value          = "$twin.tags.Tenant"
    endpoint_names = ["export", "export2"]
  }

  tags = {
    Name = var.environment_name
  }
}
