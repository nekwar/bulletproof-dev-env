
resource "time_static" "now" {}

locals {

  // build some tags for all things
  tags = merge(
    { # excludes kube-specific tags
      "stack"   = var.name
      "created" = time_static.now.rfc3339
      "kubernetes.io/cluster/${var.name}" = "owned"
    },
    var.extra_tags
  )

}
