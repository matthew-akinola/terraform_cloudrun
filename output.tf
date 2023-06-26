# Display the service URL
output "django_service_url" {
  value = google_cloud_run_service.django_blog.status[0].url
}

output "fastapi_service_url" {
  value = google_cloud_run_service.fastapi_public.status[0].url
}