#!/bin/bash

# Function to print green text
print_green() {
  echo -e "\033[32m$1\033[0m"
}

# Check if the namespace is provided as an environment variable
if [ -z "$NS" ]; then
  print_green "Please provide the namespace as an environment variable."
  print_green "Usage: NS=your-namespace ./openshift-gather.sh"
  exit 1
fi

# Set the CRD name
crd_name="trustyaiservices.trustyai.opendatahub.io"

# Set the output Markdown file name
output_file="gather_results.md"

# Initialize the Markdown file
echo "# Gather Results" > $output_file
echo "" >> $output_file

# Get the TrustyAI operator logs and events
print_green "Retrieving TrustyAI operator logs and events..."
echo "## TrustyAI Operator" >> $output_file
echo "" >> $output_file

operator_deployment="trustyai-service-operator-controller-manager"
operator_namespace="opendatahub"

echo "### Deployment: $operator_deployment" >> $output_file
echo "" >> $output_file

echo "#### Logs" >> $output_file
echo "" >> $output_file
echo "\`\`\`" >> $output_file
oc logs deployment/$operator_deployment -n $operator_namespace >> $output_file
echo "\`\`\`" >> $output_file
echo "" >> $output_file

echo "#### Events" >> $output_file
echo "" >> $output_file
echo "\`\`\`" >> $output_file
oc describe deployment $operator_deployment -n $operator_namespace >> $output_file
echo "\`\`\`" >> $output_file
echo "" >> $output_file

# Get all instances of the CRD
print_green "Retrieving TrustyAI service instances..."
echo "## TrustyAI Services" >> $output_file
echo "" >> $output_file
echo "\`TrustyAIService\` in namespace \`$NS\`:" >> $output_file
echo "" >> $output_file

instances=$(oc get $crd_name -n $NS -o jsonpath='{.items[*].metadata.name}')

# Loop through each instance
for instance in $instances; do
  print_green "Processing instance: $instance"
  echo "### $instance" >> $output_file
  echo "" >> $output_file

  echo "#### YAML" >> $output_file
  echo "" >> $output_file
  echo "\`\`\`" >> $output_file
  oc get $crd_name $instance -n $NS -o yaml >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  echo "#### Events" >> $output_file
  echo "" >> $output_file
  echo "\`\`\`" >> $output_file
  oc describe $crd_name $instance -n $NS >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  # Get the PVC YAML and events
  print_green "Retrieving PVC for instance: $instance"
  echo "#### PVC: $instance-pvc" >> $output_file
  echo "" >> $output_file
  echo "##### YAML" >> $output_file
  echo "\`\`\`" >> $output_file
  oc get pvc $instance-pvc -n $NS -o yaml >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file
  echo "##### Events" >> $output_file
  echo "\`\`\`" >> $output_file
  oc describe pvc $instance-pvc -n $NS >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  # Get the route YAML and events
  print_green "Retrieving route for instance: $instance"
  echo "#### Route: $instance" >> $output_file
  echo "" >> $output_file
  echo "##### YAML" >> $output_file
  echo "\`\`\`" >> $output_file
  oc get route $instance -n $NS -o yaml >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file
  echo "##### Events" >> $output_file
  echo "\`\`\`" >> $output_file
  oc describe route $instance -n $NS >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  # Get the service YAML and events
  print_green "Retrieving service for instance: $instance"
  echo "#### Service: $instance" >> $output_file
  echo "" >> $output_file
  echo "##### YAML" >> $output_file
  echo "\`\`\`" >> $output_file
  oc get service $instance -n $NS -o yaml >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file
  echo "##### Events" >> $output_file
  echo "\`\`\`" >> $output_file
  oc describe service $instance -n $NS >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  # Get the TLS service YAML and events
  print_green "Retrieving TLS service for instance: $instance"
  echo "#### TLS Service: $instance-tls" >> $output_file
  echo "" >> $output_file
  echo "##### YAML" >> $output_file
  echo "\`\`\`" >> $output_file
  oc get service $instance-tls -n $NS -o yaml >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file
  echo "##### Events" >> $output_file
  echo "\`\`\`" >> $output_file
  oc describe service $instance-tls -n $NS >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  # Get the pod name associated with the deployment (same name as the CRD instance)
  pod_name=$(oc get pods -n $NS -l app=$instance -o jsonpath='{.items[0].metadata.name}')

  print_green "Retrieving pod logs for instance: $instance"
  echo "#### Pod Logs" >> $output_file
  echo "" >> $output_file

  echo "##### trustyai-service container" >> $output_file
  echo "" >> $output_file
  echo "\`\`\`" >> $output_file
  oc logs $pod_name -n $NS -c trustyai-service >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  echo "##### oauth-proxy container" >> $output_file
  echo "" >> $output_file
  echo "\`\`\`" >> $output_file
  oc logs $pod_name -n $NS -c oauth-proxy >> $output_file
  echo "\`\`\`" >> $output_file
  echo "" >> $output_file

  print_green "Retrieving input directory files for instance: $instance"
  echo "#### Input Directory Files" >> $output_file
  echo "" >> $output_file

  # Get the list of files in the /input directory
  files=$(oc exec $pod_name -n $NS -c trustyai-service -- sh -c "ls /input")

  if [ -z "$files" ]; then
    echo "No files found" >> $output_file
  else
    echo "\`\`\`" >> $output_file
    oc exec $pod_name -n $NS -c trustyai-service -- sh -c "ls -lh /input" >> $output_file
    echo "\`\`\`" >> $output_file
    echo "" >> $output_file

    # Loop through each file and display its line count
    for file in $files; do
      echo "##### File: $file" >> $output_file
      echo "" >> $output_file
      echo "Line count:" >> $output_file
      echo "\`\`\`" >> $output_file
      oc exec $pod_name -n $NS -c trustyai-service -- sh -c "wc -l /input/$file" >> $output_file
      echo "\`\`\`" >> $output_file
      echo "" >> $output_file
    done
  fi
done
