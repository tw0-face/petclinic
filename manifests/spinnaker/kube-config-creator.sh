context=$(kubectl config current-context)
cluster=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$context\")].context.cluster}")
server=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$cluster\")].cluster.server}")
ca=$(kubectl get -n spinnaker secret/spinnaker-service-account -o jsonpath='{.data.ca\.crt}')
token=$(kubectl get -n spinnaker secret/spinnaker-service-account -o jsonpath='{.data.token}' | base64 --decode)

echo "
apiVersion: v1
kind: Config
clusters:
- name: ${cluster}
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: spinnaker-service-account-context
  context:
    cluster: ${cluster}
    namespace: spinnaker
    user: spinnaker-service-account
current-context: spinnaker-service-account-context
users:
- name: spinnaker-service-account
  user:
    token: ${token}
" > manifests/spinnaker/spinnaker-prod-kubeconfig.yaml