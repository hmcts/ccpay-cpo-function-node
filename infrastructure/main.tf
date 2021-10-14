provider "azurerm" {
  features {}
}

locals {
  vaultName = join("-", [var.core_product, var.env])

  s2sUrl = "http://rpe-service-auth-provider-${var.env}.service.core-compute-${var.env}.internal"
  s2s_rg_prefix               = "rpe-service-auth-provider"
  s2s_key_vault_name          = var.env == "preview" || var.env == "spreview" ? join("-", ["s2s", "aat"]) : join("-", ["s2s", var.env])
  s2s_vault_resource_group    = var.env == "preview" || var.env == "spreview" ? join("-", [local.s2s_rg_prefix, "aat"]) : join("-", [local.s2s_rg_prefix, var.env])

  subscription_name = "defaultServiceCallbackSubscription"

}

data "azurerm_resource_group" "rg" {
  name     = join("-", [var.product, var.env])
}

data "azurerm_key_vault" "ccpay_cpo_key_vault" {
  name = "${local.vaultName}"
  resource_group_name = join("-", [var.core_product, var.env])
}

data "azurerm_key_vault" "s2s_key_vault" {
  name                = local.s2s_key_vault_name
  resource_group_name = local.s2s_vault_resource_group
}

data "azurerm_key_vault_secret" "s2s_secret" {
  name          = "microservicekey-ccpay-cpo-function-node"
  key_vault_id  = data.azurerm_key_vault.s2s_key_vault.id
}

data "azurerm_servicebus_namespace" "ccpay_servicebus_namespce" {
  name                = join("-", [var.product, "servicebus", var.env])
  resource_group_name = join("-", [var.core_product, var.env])
}

module "topic_cpo" {
  source                = "git@github.com:hmcts/terraform-module-servicebus-topic"
  name                  = "ccpay-cpo-Topic"
  namespace_name        = data.azurerm_servicebus_namespace.ccpay_servicebus_namespce.name
  resource_group_name   = data.azurerm_resource_group.rg.name
}

module "subscription_cpo" {
  source                = "git@github.com:hmcts/terraform-module-servicebus-subscription"
  name                  = local.subscription_name
  namespace_name        = data.azurerm_servicebus_namespace.ccpay_servicebus_namespce.name
  topic_name            = module.topic_cpo.name
  resource_group_name   = data.azurerm_resource_group.rg.name
  max_delivery_count    = "10"
  # forward_dead_lettered_messages_to = module.queue.name
}

resource "azurerm_key_vault_secret" "cpo-topic-primary-send-listen-shared-access-key" {
  name         = "cpo-topic-primary-send-listen-shared-access-key"
  value        = module.topic_cpo.primary_send_and_listen_shared_access_key
  key_vault_id = data.azurerm_key_vault.ccpay_key_vault.id
}

resource "azurerm_key_vault_secret" "ccpay_cpo_s2s_secret" {
  name          = "ccpay-cpo-s2s-secret"
  value         = data.azurerm_key_vault_secret.s2s_secret.value
  key_vault_id  = data.azurerm_key_vault.ccpay_cpo_key_vault.id
}