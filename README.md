Find official docs here: [Kong EE Gateway Install](https://docs.konghq.com/enterprise/2.4.x/deployment/installation/kong-on-kubernetes/)

```sh
psql -d "postgresql://kong:kong@192.168.1.67:5432/kong" -c "select now()"
psql -d "postgresql://kong:kong@192.168.1.68:5432/kong" -c "select now()"
```

```sh
helm repo add jetstack  https://charts.jetstack.io
helm repo add kong      https://charts.konghq.com
helm repo update
```

```sh
kubectl create namespace cert-manager --dry-run=client -oyaml | kubectl apply -f - --context blue
kubectl create namespace cert-manager --dry-run=client -oyaml | kubectl apply -f - --context green
```

```sh
helm --kube-context blue  install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --values ./cert-manager/helm-jetstack-certmanager-values.yml
helm --kube-context green install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --values ./cert-manager/helm-jetstack-certmanager-values.yml
```

```sh
kubectl apply -f ./cert-manager/bootstrap-selfsigned-issuer.yml --context blue
kubectl apply -f ./cert-manager/bootstrap-selfsigned-issuer.yml --context green
```

```sh
kubectl apply -f ./kongee/kong-tls-selfsigned-cert.yml --context blue
kubectl apply -f ./kongee/kong-tls-selfsigned-cert.yml --context green
```

```sh
mkdir -p /tmp/kong
docker run -it --rm --pull always --user root --volume /tmp/kong:/tmp/kong:z docker.io/kong/kong -- kong hybrid gen_cert /tmp/kong/tls.crt /tmp/kong/tls.key
sudo chown $USER -R /tmp/{kong,kong/*}
```

```sh
kubectl create secret tls kong-cluster-cert --namespace kong --cert=/tmp/kong/tls.crt --key=/tmp/kong/tls.key --dry-run=client -oyaml | kubectl apply -f - --context blue
kubectl create secret tls kong-cluster-cert --namespace kong --cert=/tmp/kong/tls.crt --key=/tmp/kong/tls.key --dry-run=client -oyaml | kubectl apply -f - --context green
```

```sh
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=${HOME}/.kong-license-data/license.json --dry-run=client -oyaml | kubectl apply -n kong -f - --context blue
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=${HOME}/.kong-license-data/license.json --dry-run=client -oyaml | kubectl apply -n kong -f - --context green
```

```sh
kubectl create secret generic kong-enterprise-superuser-password -n kong \
    --from-literal=password='kong_admin' --dry-run=client -oyaml \
  | kubectl apply -f - --context blue

kubectl create secret generic kong-enterprise-superuser-password -n kong \
    --from-literal=password='kong_admin' --dry-run=client -oyaml \
  | kubectl apply -f - --context green
```

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

```sh
helm install dataplane    kong/kong --namespace kong --values ./kongee/dataplane.yml    --set ingressController.installCRDs=false --kube-context blue
helm install controlplane kong/kong --namespace kong --values ./kongee/controlplane.yml --set ingressController.installCRDs=false --kube-context blue
```

```sh
helm install dataplane    kong/kong --namespace kong --values ./kongee/dataplane.yml    --set ingressController.installCRDs=false --kube-context green
helm install controlplane kong/kong --namespace kong --values ./kongee/controlplane.yml --set ingressController.installCRDs=false --kube-context green
```

```sh
kubectl --context blue  get svc -A
kubectl --context green get svc -A
kubectl --context blue  get ingress -A
kubectl --context green get ingress -A
```
