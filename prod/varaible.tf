variable "resource_group" {
  type = string
}

variable "environment" {
  type = string
}


variable "location" {
    type = string
}

variable "vnet_name" {
  
    default = "testvnet"
  
}

variable "address_space" {
    default = "10.0.0.0/16"
  
}

variable "subnet_name" {
 default = ["subnet-1","subnet-2"]
}
variable "subnet_prefixes" {
    type = list(string)
    default = [ "10.0.1.0/24","10.0.2.0/24" ]
  
}

variable "pubip" {
 type        = string
  description = "Public IP name in Azure"
}

variable "network_interface_name" {
  type        = string
  description = "NIC name in Azure"

}
variable "windows_vm_name" {
  type        = string
}

variable "adminusername" {
    description ="vm user name"
}


variable "resource_group_names" {
  type    = map
  default = {
    dev  = "app1-rg"
    test = "app2-rg"
  
  }
}

variable "storage_1" {
  type = string
  
}