#!/bin/bash

set -e
set -o nounset
set -o pipefail

THIS_SCRIPT_DIR=$(dirname "$0")
KIND_CONFIG_FILE="$THIS_SCRIPT_DIR/kind_config.yaml"
KIND_CLUSTER_NAME="kind"

if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed. Please install kind and try again."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl and try again."
    exit 1
fi

if kind get clusters | grep -q "^$KIND_CLUSTER_NAME$"; then
        echo "A cluster is already up."
        exit 0
fi

if [[ ! -f "$KIND_CONFIG_FILE" ]]; then
    echo "Error: Configuration file $KIND_CONFIG_FILE not found."
    exit 1
fi

# create a k8s cluster
kind create cluster --config "$KIND_CONFIG_FILE" --name "$KIND_CLUSTER_NAME"
