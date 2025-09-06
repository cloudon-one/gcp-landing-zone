

resource "kubernetes_namespace" "load_testing" {
  count = var.performance_config.load_testing_enabled ? 1 : 0

  metadata {
    name = "load-testing"
    labels = {
      "purpose"     = "load-testing"
      "environment" = "testing"
    }
  }
}

resource "kubernetes_deployment" "ab_load_test_runner" {
  count = var.performance_config.load_testing_enabled ? 1 : 0

  metadata {
    name      = "ab-load-test-runner"
    namespace = kubernetes_namespace.load_testing[0].metadata[0].name
    labels = {
      app = "ab-load-test-runner"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ab-load-test-runner"
      }
    }

    template {
      metadata {
        labels = {
          app = "ab-load-test-runner"
        }
      }

      spec {
        priority_class_name = "low-priority"

        container {
          name              = "ab-load-test-runner"
          image             = "httpd:alpine"
          image_pull_policy = "IfNotPresent"

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
          }

          volume_mount {
            name       = "load-test-scripts"
            mount_path = "/scripts"
          }

          command = ["/bin/sh"]
          args = [
            "-c",
            "apk add --no-cache apache2-utils && while true; do sleep 3600; done"
          ]
        }

        volume {
          name = "load-test-scripts"
          config_map {
            name = kubernetes_config_map.ab_load_test_scripts[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "ab_load_test_scripts" {
  count = var.performance_config.load_testing_enabled ? 1 : 0

  metadata {
    name      = "ab-load-test-scripts"
    namespace = kubernetes_namespace.load_testing[0].metadata[0].name
  }

  data = {
    "burst-test.sh" = <<-EOT
      #!/bin/sh
      echo "Starting burst capacity test..."
      
      # Test 1: Burst load (50 concurrent users for 30 seconds)
      echo "=== Burst Test ==="
      ab -n 1000 -c 50 -t 30 http://fintech-api.production.svc.cluster.local:8080/health
      
      # Test 2: Sustained load (20 concurrent users for 2 minutes)
      echo "=== Sustained Test ==="
      ab -n 2000 -c 20 -t 120 http://fintech-api.production.svc.cluster.local:8080/health
      
      # Test 3: Peak load (100 concurrent users for 1 minute)
      echo "=== Peak Test ==="
      ab -n 2000 -c 100 -t 60 http://fintech-api.production.svc.cluster.local:8080/health
      
      echo "Load testing completed"
    EOT

    "peak-test.sh" = <<-EOT
      #!/bin/sh
      echo "Starting peak load test..."
      
      # Test with high concurrency
      ab -n 5000 -c 100 -t 300 http://fintech-api.production.svc.cluster.local:8080/api/v1/endpoint
      
      echo "Peak load testing completed"
    EOT
  }
}

resource "kubernetes_service" "ab_load_test_runner" {
  count = var.performance_config.load_testing_enabled ? 1 : 0

  metadata {
    name      = "ab-load-test-runner"
    namespace = kubernetes_namespace.load_testing[0].metadata[0].name
  }

  spec {
    selector = {
      app = "ab-load-test-runner"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_cron_job_v1" "scheduled_ab_load_test" {
  count = var.performance_config.load_testing_enabled ? 1 : 0

  metadata {
    name      = "scheduled-ab-load-test"
    namespace = kubernetes_namespace.load_testing[0].metadata[0].name
  }

  spec {
    schedule = "0 2 * * *" // Run daily at 2 AM

    job_template {
      metadata {
        name = "scheduled-ab-load-test"
      }

      spec {
        template {
          metadata {
            name = "scheduled-ab-load-test"
          }

          spec {
            restart_policy      = "Never"
            priority_class_name = "low-priority"

            container {
              name              = "ab-load-test-runner"
              image             = "httpd:alpine"
              image_pull_policy = "IfNotPresent"

              resources {
                requests = {
                  cpu    = "1"
                  memory = "2Gi"
                }
                limits = {
                  cpu    = "4"
                  memory = "8Gi"
                }
              }

              volume_mount {
                name       = "load-test-scripts"
                mount_path = "/scripts"
              }

              command = ["/bin/sh"]
              args = [
                "-c",
                "apk add --no-cache apache2-utils && chmod +x /scripts/peak-test.sh && /scripts/peak-test.sh"
              ]
            }

            volume {
              name = "load-test-scripts"
              config_map {
                name = kubernetes_config_map.ab_load_test_scripts[0].metadata[0].name
              }
            }
          }
        }
      }
    }
  }
} 