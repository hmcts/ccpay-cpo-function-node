variable "core_product" {
  type    = string
  default = "ccpay"
}

variable "component" {
  type    = string
  default = "ccpay-cpo-function-node"

}

variable "team_name" {
  type    = string
  default = "FeesAndPay"

}

variable "location" {
  type    = string
  default = "UK South"
}

variable "env" {
  type = string
}
variable "product" {
  type    = string
  default = "ccpay"
}

variable "subscription" {
  type    = string
}

variable "common_tags" {
  type = map(string)
}


