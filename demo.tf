# This deploys our Aptible Demo App
# https://www.aptible.com/documentation/deploy/tutorials/deploy-demo-app.html

# TODO: Enter your account handle here
data "aptible_environment" "env" {
  handle = "env-test"
}

resource "aptible_app" "env-test" {
  env_id = data.aptible_environment.env.env_id
  handle = "env-test"
  config = {
    "APTIBLE_DOCKER_IMAGE" = "quay.io/aptible/deploy-demo-app"
    "DATABASE_URL"         = aptible_database.env-pg.default_connection_url
    "REDIS_URL"            = aptible_database.env-redis.default_connection_url
  }
  service {
    process_type           = "web"
    container_count        = 2
    container_memory_limit = 512
  }
  service {
    process_type           = "background"
    container_count        = 0
    container_memory_limit = 512
  }

  # https://www.aptible.com/documentation/deploy/tutorials/deploy-demo-app.html#run-database-migrations
  # This is a one-time execution at application creation for demo purposes.
  # If you need to run migrations on each app release, you should use a before_release command
  # https://www.aptible.com/documentation/deploy/reference/apps/aptible-yml.html#before-release
  provisioner "local-exec" {
    command = "aptible ssh --app env-test python migrations.py"
  }
}

resource "aptible_database" "env-pg" {
  env_id         = data.aptible_environment.env.env_id
  handle         = "env-pg"
  database_type  = "postgresql"
  container_size = 512
  disk_size      = 10
}

resource "aptible_database" "env-redis" {
  env_id         = data.aptible_environment.env.env_id
  handle         = "env-redis"
  database_type  = "redis"
  container_size = 512
  disk_size      = 10
}

resource "aptible_endpoint" "env-app-public-endpoint" {
  env_id         = data.aptible_environment.env.env_id
  resource_type  = "app"
  process_type   = "web"
  resource_id    = aptible_app.env-test.app_id
  default_domain = true
  endpoint_type  = "https"
  container_port = 5000
}
