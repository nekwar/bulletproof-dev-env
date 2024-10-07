locals {

  k0s_roles = ["controller", "worker", "controller+worker"]

  // standard k0s ingresses
  k0s_ingresses = {
    "k0s" = {
      description = "k0s ingress for Kube API"
      nodegroups  = [for k, ng in var.nodegroups : k if ng.role == "controller" || ng.role == "controller+worker"]

      routes = {
        "kube" = {
          port_incoming = 6443
          port_target   = 6443
          protocol      = "TCP"
        },
        "konnectivity" = {
          port_incoming = 8132
          port_target = 8132
          protocol = "TCP"
        }
      }
    }
  }

  k0s_securitygroups = {
    "permissive" = {
      description = "Common SG for all cluster machines"
      nodegroups  = [for n, ng in var.nodegroups : n]
      ingress_ipv4 = [
        {
          description : "Permissive internal traffic [BAD RULE]"
          from_port : 0
          to_port : 0
          protocol : "-1"
          self : true
          cidr_blocks : []
        },
        {
          description : "Permissive external traffic [BAD RULE]"
          from_port : 0
          to_port : 0
          protocol : "-1"
          self : false
          cidr_blocks : ["0.0.0.0/0"]
        }
      ]
      egress_ipv4 = [
        {
          description : "Permissive outgoing traffic"
          from_port : 0
          to_port : 0
          protocol : "-1"
          cidr_blocks : ["0.0.0.0/0"]
          self : false
        }
      ]
    }
  }

  k0s_url = module.provision.ingresses["k0s"].lb_dns

  // flatten nodegroups into a set of objects with the info needed for each node, by combining the group details with the node detains
  k0sctl_hosts_ssh = merge([for k, ng in local.nodegroups : { for l, ngn in ng.nodes : ngn.label => {
    label : ngn.label
    role : ng.role

    address : ngn.public_address

    ssh_address : ngn.public_ip
    ssh_user : ng.ssh_user
    ssh_port : ng.ssh_port
    ssh_key_path : abspath(local_sensitive_file.ssh_private_key.filename)
  } if contains(local.k0s_roles, ng.role) && ng.connection == "ssh" }]...)
  k0sctl_hosts_winrm = merge([for k, ng in local.nodegroups : { for l, ngn in ng.nodes : ngn.label => {
    label : ngn.label
    role : ng.role

    address : ngn.public_address

    winrm_address : ngn.public_ip
    winrm_user : ng.winrm_user
    winrm_password : var.windows_password
    winrm_useHTTPS : ng.winrm_useHTTPS
    winrm_insecure : ng.winrm_insecure
  } if contains(local.k0s_roles, ng.role) && ng.connection == "winrm" }]...)

  k0sctl_yaml = <<-EOT
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: ${var.name}
spec:
  hosts:
%{~for h in local.k0sctl_hosts_ssh}
  # ${h.label} (ssh)
  - role: ${h.role}
    ssh:
      address: ${h.ssh_address}
      user: ${h.ssh_user}
      keyPath: ${h.ssh_key_path}
    installFlags:
      - "--enable-cloud-provider"
      - "--kubelet-extra-args=\"--cloud-provider=external\""
%{~endfor}
%{~for h in local.k0sctl_hosts_winrm}
  # ${h.label} (winrm)
  - role: ${h.role}
    winRM:
      address: ${h.winrm_address}
      user: ${h.winrm_user}
      password: ${h.winrm_password}
      useHTTPS: ${h.winrm_useHTTPS}
      insecure: ${h.winrm_insecure}
    installFlags:
      - "--enable-cloud-provider",
      - "--kubelet-extra-args=\"--cloud-provider=external\""
%{~endfor}
  k0s:
    version: 1.31.1+k0s.0
    config:
      apiVersion: k0s.k0sproject.io/v1beta1
      kind: ClusterConfig
      metadata:
        name: ${var.name}
      spec:
        api:
          externalAddress: ${local.k0s_url}
          sans: ${local.k0s_url}
        network:
          provider: "calico"
        extensions:
          helm:
            repositories:
            - name: "aws-cloud-controller-manager"
              url: "https://kubernetes.github.io/cloud-provider-aws"
            - name: "aws-ebs-csi-driver"
              url: "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
            charts:
            - name: "aws-ebs-csi"
              chartname: "aws-ebs-csi-driver/aws-ebs-csi-driver"
              namespace: kube-system
              values: |
                node:
                  kubeletPath: /var/lib/k0s/kubelet
            - name: "aws-ccm"
              chartname: "aws-cloud-controller-manager/aws-cloud-controller-manager"
              namespace: kube-system
              values: |
                nodeSelector:
                  node-role.kubernetes.io/control-plane: "true"
                args:
                  - --v=2
                  - --cloud-provider=aws
                  - --allocate-node-cidrs=false
                  - --cluster-cidr=10.96.0.0/16
                  - --cluster-name=${var.name}
                  - --configure-cloud-routes=false
EOT

}

output "k0sctl_yaml" {
  description = "k0sctl config file yaml"
  sensitive   = true
  value       = local.k0sctl_yaml
}
