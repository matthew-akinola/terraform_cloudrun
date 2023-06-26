variable "credentials_file" {
  description = "Path to the Google Cloud credentials JSON file"
  default     = "/home/dell/Downloads/gcp.json"
}

variable "project_id" {
  description = "Google Cloud project ID"
  default     = "forward-server-390416"
}

variable "region" {
  description = "Google Cloud region"
  default     = "us-central1"
}


variable "django_image" {
  description = "Django container image to deploy"

  default     = "gcr.io/forward-server-390416/django_blog:latest"
}

variable "fastapi_image" {
  description = "fastapi container image to deploy"

  default     = "gcr.io/forward-server-390416/fastapi"
}


variable "django_container_port" {
  description = "Django container port to expose"
  type        = number
  default     = 8000
}



variable "fastapi_container_port" {
  description = "fastapi container port to expose"
  type        = number
  default     = 8001
}


variable "vpc_connectors" {
  description = "VPC connectors configuration"
  type        = list(object({
    name           = string
    region         = string
    ip_cidr_range  = string
    subnet_name    = string
    machine_type   = string
    min_instances  = number
    max_instances  = number
  }))
  default = [
    {
      name           = "central-serverless"
      region         = "us-central1"
      ip_cidr_range  = "10.10.11.0/28"
      subnet_name    = "subnet"
      machine_type   = "e2-micro"
      min_instances  = 2
      max_instances  = 3
    }
  ]
}
