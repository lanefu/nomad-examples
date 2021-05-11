
job "fabio" {
  priority = 100
  meta {
    fabio_version = "1.5.15"
    fabio_go_version = "1.15.5"
    fabio_arch = "arm"
    binary_name = "fabio-${attr.meta.fabio_version}-go${attr.meta.nomad_go_version}-linux_${attr.meta.nomad_arch}"
    source = "https://github.com/fabiolb/fabio/releases/download/v${attr.meta.fabio_version}/${attr.meta.binary_name}"
    fabio_log_format = "$request_host:80 $remote_host - - [$time_common] \"$request\" $response_status $response_body_size \"$header.Referer\" \"$header.User-Agent\""
  }
  datacenters = ["dc1"]

  type = "service"

   constraint {
     attribute = "${meta.group_names}"
     operator = "regexp"
     value = "hashi_cluster"
  }
   constraint {

     attribute = "${attr.kernel.name}"
     value     = "linux"
   }

  update {
    max_parallel = 1
    
    min_healthy_time = "20s"
    
    healthy_deadline = "3m"
    
    auto_revert = true
    
    canary = 1
  }

  group "fabio" {
    count = 3
        network {
          port "http" {
            static = 9999
          }

          port "ui" {
            static = 9998
          }
          
	  port "https" {
            static = 9997
	  
          }
        }

    restart {
      attempts              = 2
      interval              = "5m"
      delay                 = "30s"
      mode                  = "fail"
    }



    task "fabio" {
      driver = "exec"




      config {
        command = "./fabio-${NOMAD_META_fabio_version}-go${NOMAD_META_fabio_go_version}-linux_${attr.cpu.arch}"

        args = ["-proxy.addr", ":9999;proto=http;pxyproto=true,:9997;proto=https;cs=consul-kv-ssl;pxyproto=true", "-proxy.cs", "cs=consul-kv-ssl;type=consul;cert=http://localhost:8500/v1/kv/ssl/",
        "-proxy.dialtimeout", "5s", "-log.access.target=stdout", "-log.access.format=${NOMAD_META_fabio_log_format}"]
      }


      artifact {
        source = "https://github.com/fabiolb/fabio/releases/download/v${NOMAD_META_fabio_version}/fabio-${NOMAD_META_fabio_version}-go${NOMAD_META_fabio_go_version}-linux_${attr.cpu.arch}"
      }

      resources {
        cpu    = 200 # 500 MHz
        memory = 100 # 256MB
      }


      service {
        name = "fabio"
        tags = ["https", "load-balancer"]

        port = "https"

      }

      service {
        name = "fabio"
        tags = ["ui", "load-balancer"]

        port = "ui"

        check {
          type     = "http"
          name     = "fabio-ui"
          interval = "10s"
          timeout  = "2s"
          path     = "/"

	  check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

    }
  }
}
