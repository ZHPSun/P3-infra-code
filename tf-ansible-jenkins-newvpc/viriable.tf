variable "public_key_name" {
  default = "mykeyjr"
}

variable "ingress_ports" {
  description = "A map of named ingress ports to allow"
  type        = map(number)
  default = {
    ssh     = 22
    http    = 80
    https   = 443
    jenkins = 8080
  }
}