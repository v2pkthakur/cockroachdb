export cluster1=aws-cluster-shared-0
export cluster2=aws-cluster-shared-1
export cluster3=aws-cluster-shared-2

export cluster1_context=aws-0
export cluster2_context=aws-1
export cluster3_context=aws-2
export control_cluster_context=hub

export cluster_organization=
export enterprise_license=

export cluster_base_domain=$(oc --context ${control_cluster_context} get dns cluster -o jsonpath='{.spec.baseDomain}')
export global_base_domain=global.${cluster_base_domain#*.}


# Deploy on Cluster1 
oc --context ${cluster1_context} new-project cockroachdb
export infrastructure=$(oc --context ${cluster1_context} get infrastructure cluster -o jsonpath='{.spec.platformSpec.type}'| tr '[:upper:]' '[:lower:]')
export uid=$(oc --context ${cluster1_context} get project cockroachdb -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'|sed 's/\/.*//')
export guid=$(oc --context ${cluster1_context} get project cockroachdb -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'|sed 's/\/.*//')
export cluster=${cluster1}
envsubst < ./values.templ.yaml > /tmp/cluster1-values.yaml
helm --kube-context ${cluster1_context} upgrade cockroachdb .  -i --create-namespace -n cockroachdb -f /tmp/cluster1-values.yaml


# Deploy on Cluster2 
oc --context ${cluster2_context} new-project cockroachdb
export infrastructure=$(oc --context ${cluster2_context} get infrastructure cluster -o jsonpath='{.spec.platformSpec.type}'| tr '[:upper:]' '[:lower:]')
export uid=$(oc --context ${cluster2_context} get project cockroachdb -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'|sed 's/\/.*//')
export guid=$(oc --context ${cluster2_context} get project cockroachdb -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'|sed 's/\/.*//')
export cluster=${cluster2}
envsubst < ./values.templ.yaml > /tmp/cluster2-values.yaml
helm --kube-context ${cluster2_context} upgrade cockroachdb .  -i --create-namespace -n cockroachdb -f /tmp/cluster2-values.yaml


# Deploy on Cluster3
oc --context ${cluster3_context} new-project cockroachdb
export infrastructure=$(oc --context ${cluster3_context} get infrastructure cluster -o jsonpath='{.spec.platformSpec.type}'| tr '[:upper:]' '[:lower:]')
export uid=$(oc --context ${cluster3_context} get project cockroachdb -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'|sed 's/\/.*//')
export guid=$(oc --context ${cluster3_context} get project cockroachdb -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'|sed 's/\/.*//')
export cluster=${cluster3}
envsubst < ./values.templ.yaml > /tmp/cluster3-values.yaml
helm --kube-context ${cluster3_context} upgrade cockroachdb .  -i --create-namespace -n cockroachdb -f /tmp/cluster3-values.yaml


export tools_pod=$(oc --context ${cluster1_context} get pods -n cockroachdb | grep tools | awk '{print $1}')
oc --context ${cluster1_context} exec $tools_pod -c tools -n cockroachdb -- /cockroach/cockroach init --certs-dir=/crdb-certs --host cockroachdb-0.${cluster1}.cockroachdb.cockroachdb.svc.clusterset.local
oc --context ${cluster1_context} exec $tools_pod -c tools -n cockroachdb -- /cockroach/cockroach node status --certs-dir=/crdb-certs --host cockroachdb-0.${cluster1}.cockroachdb.cockroachdb.svc.clusterset.local

oc --context ${cluster1_context} exec $tools_pod -c tools -n cockroachdb -- /cockroach/cockroach sql --execute='CREATE USER dba WITH PASSWORD dba;' --certs-dir=/crdb-certs --host cockroachdb-0.${cluster1}.cockroachdb.cockroachdb.svc.clusterset.local

oc --context ${cluster1_context} exec $tools_pod -c tools -n cockroachdb -- /cockroach/cockroach sql --execute='GRANT admin TO dba WITH ADMIN OPTION;' --certs-dir=/crdb-certs --host cockroachdb-0.${cluster1}.cockroachdb.cockroachdb.svc.clusterset.local

oc --context ${cluster1_context} exec $tools_pod -c tools -n cockroachdb -- /cockroach/cockroach sql --certs-dir=/crdb-certs --host cockroachdb-0.${cluster1}.cockroachdb.cockroachdb.svc.clusterset.local --echo-sql --execute='SET CLUSTER SETTING cluster.organization = '\""${cluster_organization}"\"';'

oc --context ${cluster1_context} exec $tools_pod -c tools -n cockroachdb -- /cockroach/cockroach sql  --certs-dir=/crdb-certs --host cockroachdb-0.${cluster1}.cockroachdb.cockroachdb.svc.clusterset.local --echo-sql --execute='SET CLUSTER SETTING enterprise.license = '\""${enterprise_license}"\"';'

