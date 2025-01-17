###################
### Variables
###################

variable REGISTRY {
  default = ""
}

# Comma delimited list of tags
variable TAGS {
  default = "latest"
}

variable CI {
  default = false
}

variable image_base {
  default = "docker-image://alpine:3.17.3"
}

variable image_goreleaser {
  default = "docker-image://goreleaser/goreleaser:v1.15.2"
}

###################
### Functions
###################

function "get_tags" {
  params = [image]
  result = [for tag in split(",", TAGS) : join("/", compact([REGISTRY, "${image}:${tag}"]))]
}

function "get_platforms_multiarch" {
  params = []
  result = CI ? ["linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64"] : []
}

function "get_output" {
  params = []
  result = CI ? ["type=registry"] : ["type=docker"]
}

###################
### Groups
###################

group "default" {
  targets = [
    "nats-kafka"
  ]
}

###################
### Targets
###################

target "goreleaser" {
  contexts = {
    goreleaser = image_goreleaser
    src = "."
  }
  args = {
    CI = CI
    GITHUB_TOKEN = ""
  }
  dockerfile = "cicd/Dockerfile_goreleaser"
}

target "nats-kafka" {
  contexts = {
    base    = image_base
    build   = "target:goreleaser"
    assets  = "cicd/assets"
  }
  args = {
    GO_APP = "nats-kafka"
  }
  dockerfile  = "cicd/Dockerfile"
  platforms   = get_platforms_multiarch()
  tags        = get_tags("nats-kafka")
  output      = get_output()
}
