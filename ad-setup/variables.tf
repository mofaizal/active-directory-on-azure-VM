#################################################################
#   Variables
#################################################################

# Generic info
variable resource_group_name {
  description = "The name of the Resource Group where the Domain Controllers resources will be created"
   default     = ""

}
variable location {
  description = "The Azure Region in which the Resource Group exists"
  default     = ""
}

# Active Directory & Domain Controller
variable prefix {
  description = "The prefix used for all resources in this example. Needs to be a short (6 characters) alphanumeric string. Example: `myprefix`."
default     = ""
}

variable "subnet_id" {
  description = "The Subnet ID which the Domain Controller's NIC should be created in. This should be have already been created seperately"
default     = ""
}
variable private_ip_address {
  description = "The private IP address for the Domain Controller's NIC"
  default     = ""
}
variable admin_username {
    description = "The username associated with the local administrator account on the virtual machine"
    default     = ""
}
variable admin_password {
  description = "The password associated with the local administrator account on the virtual machine"
  default     = ""
}
variable "active_directory_domain" {
  description = "The name of the Active Directory domain, for example `consoto.local`"
  default     = ""
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
    default     = ""
}