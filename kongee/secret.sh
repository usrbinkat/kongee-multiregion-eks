kubectl create secret generic kong-postgres-credentials -n kong --dry-run=client -oyaml \
    --from-literal=pg_user=kong \
    --from-literal=pg_database=kong \
    --from-literal=pg_password=kong \
    --from-literal=pg_host=postgres-postgresql.kong.svc.cluster.local \
    --from-literal=pg_ro_user=kong \
    --from-literal=pg_ro_database=kong \
    --from-literal=pg_ro_password=kong \
    --from-literal=pg_ro_host=postgres-postgresql-read.kong.svc.cluster.local \
  | kubectl apply -f -
