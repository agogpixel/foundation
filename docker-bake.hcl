variable "IMAGE_NAME" {
  default = "agogpixel/foundation"
}

variable "IMAGE_TAG" {
  default = ""
}

group "default" {
  targets = ["3.14"]
}

target "3.14" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    alpine_version = "3.14"
  }
  tags = [
    notequal("",IMAGE_TAG) ? "${IMAGE_NAME}:${IMAGE_TAG}" : "",
    notequal("",IMAGE_TAG) ? "${IMAGE_NAME}:${IMAGE_TAG}-3.14" : "",
    "${IMAGE_NAME}:3.14",
    "${IMAGE_NAME}:latest"
  ]
}

target "3.13" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    alpine_version = "3.13"
  }
  tags = [
    notequal("",IMAGE_TAG) ? "${IMAGE_NAME}:${IMAGE_TAG}-3.13" : "",
    "${IMAGE_NAME}:3.13"
  ]
}

target "3.12" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    alpine_version = "3.12"
  }
  tags = [
    notequal("",IMAGE_TAG) ? "${IMAGE_NAME}:${IMAGE_TAG}-3.12" : "",
    "${IMAGE_NAME}:3.12"
  ]
}

target "3.11" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    alpine_version = "3.11"
  }
  tags = [
    notequal("",IMAGE_TAG) ? "${IMAGE_NAME}:${IMAGE_TAG}-3.11" : "",
    "${IMAGE_NAME}:3.11"
  ]
}

target "edge" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    alpine_version = "edge"
  }
  tags = [
    notequal("",IMAGE_TAG) ? "${IMAGE_NAME}:${IMAGE_TAG}-edge" : "",
    "${IMAGE_NAME}:edge"
  ]
}
