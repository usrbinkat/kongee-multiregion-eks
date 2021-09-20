Find official docs here: [Kong EE Gateway Install](https://docs.konghq.com/enterprise/2.4.x/deployment/installation/kong-on-kubernetes/)

### 0. test connectivity
```sh
psql -d "postgresql://kong:kong@192.168.1.67:5432/kong" -c "select now()"
psql -d "postgresql://kong:kong@192.168.1.68:5432/kong" -c "select now()"
```

### 1. add helm repos
```sh
helm repo add jetstack  https://charts.jetstack.io
helm repo add kong      https://charts.konghq.com
helm repo update
```

### 2. CertManager (optional)
```sh
kubectl create namespace cert-manager --dry-run=client -oyaml | kubectl apply -f - --context blue
kubectl create namespace cert-manager --dry-run=client -oyaml | kubectl apply -f - --context green
```

### 3. CertManager (optional)
```sh
helm --kube-context blue  upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --values ./cert-manager/helm-jetstack-certmanager-values.yml
helm --kube-context green upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --values ./cert-manager/helm-jetstack-certmanager-values.yml
```

### 4. CertManager (optional)
```sh
kubectl apply -f ./cert-manager/bootstrap-selfsigned-issuer.yml --context blue
kubectl apply -f ./cert-manager/bootstrap-selfsigned-issuer.yml --context green
```

### 5. Create certificate for kong manager and portal resources
```sh
kubectl apply -f ./kongee/kong-tls-selfsigned-cert.yml --context blue
kubectl apply -f ./kongee/kong-tls-selfsigned-cert.yml --context green
```

### 6. Create hybrid dataplane and controlplane mutual trust certificates
```sh
mkdir -p /tmp/kong
docker run -it --rm --pull always --user root --volume /tmp/kong:/tmp/kong:z docker.io/kong/kong -- kong hybrid gen_cert /tmp/kong/tls.crt /tmp/kong/tls.key
sudo chown $USER -R /tmp/{kong,kong/*}
```

### 7. Create tls secrets for mutual trust certificates
```sh
kubectl create secret tls kong-cluster-cert --namespace kong --cert=/tmp/kong/tls.crt --key=/tmp/kong/tls.key --dry-run=client -oyaml | kubectl apply -f - --context blue
kubectl create secret tls kong-cluster-cert --namespace kong --cert=/tmp/kong/tls.crt --key=/tmp/kong/tls.key --dry-run=client -oyaml | kubectl apply -f - --context green
```

### 8. Create license secret
```sh
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=${HOME}/.kong-license-data/license.json --dry-run=client -oyaml | kubectl apply -n kong -f - --context blue
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=${HOME}/.kong-license-data/license.json --dry-run=client -oyaml | kubectl apply -n kong -f - --context green
```

### 9. Create `kong_admin` super user password secret
```sh
kubectl create secret generic kong-enterprise-superuser-password -n kong --dry-run=client -oyaml --from-literal=password='kong_admin' | kubectl apply -f - --context blue
kubectl create secret generic kong-enterprise-superuser-password -n kong --dry-run=client -oyaml --from-literal=password='kong_admin' | kubectl apply -f - --context green
```

### 10. create kong web session configurations for manager and portal (example)
```sh
kubectl create secret generic kong-session-config -n kong \
    --from-file=admin_gui_session_conf=./kongee/contrib/admin_gui_session_conf \
    --from-file=portal_session_conf=./kongee/contrib/portal_session_conf \
    --dry-run=client -oyaml \
  | kubectl apply -f - --context blue

kubectl create secret generic kong-session-config -n kong \
    --from-file=admin_gui_session_conf=./kongee/contrib/admin_gui_session_conf \
    --from-file=portal_session_conf=./kongee/contrib/portal_session_conf \
    --dry-run=client -oyaml \
  | kubectl apply -f - --context green
```

### 11. Create postgres credential secret
```sh
kubectl create secret generic kong-postgres-credentials -n kong --dry-run=client -oyaml \
    --from-literal=pg_user=kong \
    --from-literal=pg_database=kong \
    --from-literal=pg_password=kong \
    --from-literal=pg_host=192.168.1.67 \
    --from-literal=pg_ro_user=kong \
    --from-literal=pg_ro_database=kong \
    --from-literal=pg_ro_password=kong \
    --from-literal=pg_ro_host=192.168.1.68 \
  | kubectl apply -f - --context blue

kubectl create secret generic kong-postgres-credentials -n kong --dry-run=client -oyaml \
    --from-literal=pg_user=kong \
    --from-literal=pg_database=kong \
    --from-literal=pg_password=kong \
    --from-literal=pg_host=192.168.1.67 \
    --from-literal=pg_ro_user=kong \
    --from-literal=pg_ro_database=kong \
    --from-literal=pg_ro_password=kong \
    --from-literal=pg_ro_host=192.168.1.68 \
  | kubectl apply -f - --context green
```

### 12. Deploy Dataplane and Controlplane
  - deploy to first cluster
```sh
helm upgrade --install dataplane    kong/kong --namespace kong --values ./kongee/dataplane.yml    --set ingressController.installCRDs=false --kube-context blue
helm upgrade --install controlplane kong/kong --namespace kong --values ./kongee/controlplane.yml --set ingressController.installCRDs=false --kube-context blue
```
  - deploy to second cluster
```sh
helm upgrade --install dataplane    kong/kong --namespace kong --values ./kongee/dataplane.yml    --set ingressController.installCRDs=false --kube-context green
helm upgrade --install controlplane kong/kong --namespace kong --values ./kongee/controlplane.yml --set ingressController.installCRDs=false --kube-context green
```

### 13. review services and ingresses (where applicable)
```sh
kubectl --context blue  get svc -A
kubectl --context green get svc -A
kubectl --context blue  get ingress -A
kubectl --context green get ingress -A
```
