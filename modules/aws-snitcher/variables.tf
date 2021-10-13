variable "config" {
    type = object({
        aws_region             = string
        account                = string
        service_name           = string
        owner                  = string
        stage                  = string
        sns_notification_email = string
        whitelisted_principals = list(string)
    })
}

variable "common_tags" {
  type = map
}

variable "key_prefix" {
  default = "aws-config-terraform-snitch"
  type = string
}

variable "history_days" {
  default = 365
  type = number
}

variable "snapshot_frequency" {
  default = "One_Hour"
  # valid: "One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"
  # (see https://docs.aws.amazon.com/config/latest/APIReference/API_ConfigSnapshotDeliveryProperties.html)
}
