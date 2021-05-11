## example paramaterized job. where you pipe direct a shell script to be executed.
## nomad job dispatch nomad-runner - < dispatch/simple-task.sh
## nomad job dispatch -meta docker_image=golang:stretch nomad-runner - < dispatch/golang-build-task.sh

job "nomad-runner" {
  datacenters = ["dc1"]
  type = "batch"

  meta {
    docker_image = "ubuntu"
  }

  parameterized {
     payload       = "required"
     meta_optional = ["docker_image"]
  }

  constraint {
    attribute = "${meta.group_names}"
    operator = "regexp"
    value = "hashi_client"
  }

  group "runner-arm" {
    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 1
      interval = "5m"

      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"

     # The "mode" parameter controls what happens when a task has restarted
     # "attempts" times within the interval. "delay" mode delays the next
     # restart until the next interval. "fail" mode does not restart the task
     # if "attempts" has been hit within the interval.
      mode = "fail"
    }


    task "runner" {
      constraint {
        attribute = "${attr.cpu.arch}"
        regexp     = "^arm"

      }
      dispatch_payload {
        file = "entrypoint.sh"
      }
      driver = "docker"

      config {
        image = "${NOMAD_META_docker_image}"
        force_pull = true
        port_map {
          http = 80
          misc = 8000
        }
        args = [ "/bin/bash", "${NOMAD_TASK_DIR}/entrypoint.sh" ]

      }

      resources {
        cpu    = 1500
        memory = 500
        network {
          mbits = 10
          port "http" {}
          port "misc" {}
        }
      }

      service {
        name = "nomad-runner-http"
        tags = ["global", "runner"]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      service {
        name = "nomad-runner-misc"
        tags = ["global", "runner"]
        port = "misc"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

    } # end of task
  } #end of group
} #end of job
