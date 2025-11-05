variable "name" {
  type    = string
  default = "alb"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
