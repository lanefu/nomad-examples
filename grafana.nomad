
job "grafana" {
  datacenters = ["montrose_heights"]

  type = "service"

   constraint {
     attribute = "${attr.kernel.name}"
     value     = "linux"
   }

   constraint {
     attribute = "${attr.cpu.arch}"
     regexp     = "arm"
   }

   constraint {
     attribute = "${meta.group_names}"
     operator = "regexp"
     value = "hashi_client"
  }
  update {
    max_parallel = 1
    
    min_healthy_time = "10s"
    
    healthy_deadline = "8m"
    
    auto_revert = false
    
    canary = 0
  }

  reschedule {
    delay          = "30s"
    delay_function = "exponential"
    max_delay      = "10m"
    unlimited      = true
  }
  group "grafana" {
    count = 1

    network {
    port "grafana_http" {
      to = 3000
      }
    }
    restart {
      attempts = 10
      interval = "5m"

      delay = "25s"

      mode = "delay"
    }



    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:master"
        ports = ["grafana_http"]
        volumes = [ 
	"/docker_app_data/grafana/varlib:/var/lib/grafana",
        "/docker_app_data/grafana/conf:/etc/grafana"
	]
      }



      resources {
        cpu    = 1200 # 500 MHz
        memory = 300 # 256MB
      }

      service {
        name = "grafana"
        tags = ["urlprefix-www.example.com/grafana cs=consul-kv-ssl"]
        port = "grafana_http"
        check {
          name     = "alive"
          path     = "/api/health"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }




    }
  }
}
