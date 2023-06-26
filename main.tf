terraform {
  required_version = ">= 1.3"

  required_providers {
    google = ">= 3.3"
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

#google api configuration
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

#fastapi public cloud run service configuration
resource "google_cloud_run_service" "fastapi_public" {
  name     = "fastapi-public-service"
  location = var.region

  template {
    spec {
      containers {
        image = var.fastapi_image

        ports {
          container_port = var.fastapi_container_port
        }
        env {
          name  = "URL"
          value = google_cloud_run_service.django_blog.status[0].url
        }
      }
      service_account_name = google_service_account.matt_svca.email
    }  
  }
   # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.run_api]
  
}

#creating public access iam_policy 
data "google_iam_policy" "fastapi_public_iam_policy" {
  binding {
    role    = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

#attaching iam_policy to fastapi cloud run service
resource "google_cloud_run_service_iam_policy" "fastapi_public_cloud_run_service_iam_policy" {
  location    = google_cloud_run_service.fastapi_public.location
  project     = google_cloud_run_service.fastapi_public.project
  service     = google_cloud_run_service.fastapi_public.name

  policy_data = data.google_iam_policy.fastapi_public_iam_policy.policy_data
}

#django private cloud_run_service configuration
resource "google_cloud_run_service" "django_blog" {
  name     = "django-service"
  location = var.region
  template {
    spec {
      containers {
        image = var.django_image
        ports {
          container_port = var.django_container_port
        }
      }
    }
  }
}

#creating a private iam_policy
data "google_iam_policy" "django_blog_iam_policy" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_service_account.matt_svca.email}",  
    ]   
  }
}

#bind private_iam_policy to django private cloud_run_service which is only accessible to fastapi service account
resource "google_cloud_run_service_iam_policy" "django_blog_cloud_run_iam_policy" {
  location    = google_cloud_run_service.django_blog.location
  project     = google_cloud_run_service.django_blog.project
  service     = google_cloud_run_service.django_blog.name
  policy_data = data.google_iam_policy.django_blog_iam_policy.policy_data
}
######
resource "google_service_account" "matt_svca" {
  description  = "Identity used by a public Cloud Run service to call private Cloud Run services."
  display_name = "matt_svca"
}

######
module "matt_vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 7.0"
  project_id   = var.project_id 
  network_name = "my-serverless-network"

  subnets = [
    {
      subnet_name   = "serverless-subnet"
      subnet_ip     = "10.10.10.0/28"
      subnet_region = "us-central1"
    }
  ]
}

#creating a serverless connector
module "serverless-connector" {
  source     = "terraform-google-modules/network/google//modules/vpc-serverless-connector-beta"
  version    = "~> 7.0"
  project_id = var.project_id
  vpc_connectors = var.vpc_connectors
  depends_on = [
    google_project_service.run_api
  ]
}