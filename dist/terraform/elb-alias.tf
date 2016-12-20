variable "dns_zone_id" {
  description = "DNS zone used for all resources"
  default     = ""
}

variable "elb_dns_name" {
  description = "DNS hostname of ELB"
  default     = ""
}

variable "elb_zone_id" {
  description = "DNS zone ID of ELB"
  default     = ""
}

variable "kubernetes_cluster" {
  description = "DNS name of kubernetes cluster"
  default     = ""
}

resource "aws_route53_record" "ingress-nginx" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.kubernetes_cluster}"
  type    = "A"

  alias {
    name                   = "${var.elb_dns_name}"
    zone_id                = "${var.elb_zone_id}"
    evaluate_target_health = false
  }                                                                                                                                                                                                                                                                 
}

resource "aws_route53_record" "ingress-nginx-wildcard" {
  zone_id = "${var.dns_zone_id}"
  name    = "*.${var.kubernetes_cluster}"
  type    = "A"

  alias {
    name                   = "${var.elb_dns_name}"
    zone_id                = "${var.elb_zone_id}"
    evaluate_target_health = false
  }                                                                                                                                                                                                                                                                 
}
