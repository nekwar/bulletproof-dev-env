# Deploy development k0s cluster 

## Deploy

Deployment of the cluster consist of two main phases:

1. Deployment of infra and k0s on top of this infra.
2. Deployment of applications on top of k0s cluster.

### AWS Prereqs

In order to deploy the cluster on AWS:

1. `terraform` and `k0sctl` to be installed.
1. Obtain user credentials and set them as environment variables.
3. Clone this repo to your machine.
2. Set infra variable according to your environment and use case in `infra/terraform/aws/terraform.tfvars` (it can be done easily by copying `infra/terraform/aws/terraform.tfvars.example` in the same folder).

### Deployment process

To deploy infra and k0s, execute following commands:

```
cd $GIT_ROOT/infra/aws
terraform apply -auto-approve
```

Here you need to wait a bit for domain name of newly created LB for the cluster to be propagated, otherwise you'll face connectivity issue. If you face this issue, just try to execute `k0sctl` related commands one more time.

```
terraform output -raw k0sctl_yaml | k0sctl apply --config -
terraform output -raw k0sctl_yaml | k0sctl kubeconfig --config - > kubeconfig
export KUBECONFIG=$GIT_ROOT/infra/aws/kubeconfig
```

Once k0s cluster is deployed, we can proceed to applications deployment

```
cd $GIT_ROOT
kubectl apply -k apps/argocd
kubectl apply -k apps/utility
```

Here you need to wait again for ArgoCD pods to be up and running (you can check it by executing `kubectl get pods -n argocd`). Then, when all ArgoCD pods are healthy, execute:

```
k apply -f apps/apps.yaml
```

## Destroy

### AWS Destroy process

To destroy the cluster, run:

```
GIT_ROOT=$(git rev-parse --show-toplevel)
kubectl delete -f $GIT_ROOT/apps/apps.yaml
cd $GIT_ROOT/infra/aws
terraform destroy -auto-approve
```
