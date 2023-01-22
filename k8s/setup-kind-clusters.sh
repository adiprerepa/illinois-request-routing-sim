#!/bin/bash

CLUSTER_1_NAME="illinois-request-routing-a"
CLUSTER_2_NAME="illinois-request-routing-b"

C1_NODE="${CLUSTER_1_NAME}-control-plane"
C2_NODE="${CLUSTER_2_NAME}-control-plane"

CLUSTER_KUBECONFIG="out/config"
mkdir -p "${CLUSTER_KUBECONFIG}"
CLUSTER_1_KUBECONFIG="${CLUSTER_KUBECONFIG}/a"
CLUSTER_2_KUBECONFIG="${CLUSTER_KUBECONFIG}/b"

if [[ -z "${CLUSTER_1_CONFIG}" ]]; then
  CLUSTER_1_CONFIG="cluster.yaml"
fi

if [[ -z "${CLUSTER_2_CONFIG}" ]]; then
  CLUSTER_2_CONFIG="cluster2.yaml"
fi

existing_clusters=$(kind get clusters)
CREATE_1=1
CREATE_2=1
if [[ $existing_clusters == *"${CLUSTER_1_NAME}"* ]]; then
  CREATE_1=0
fi

if [[ $existing_clusters == *"${CLUSTER_2_NAME}"* ]]; then
  CREATE_2=0
fi

if ! (kind create cluster --name "${CLUSTER_1_NAME}" --config "${CLUSTER_1_CONFIG}" -v4 --wait=180s); then
  echo "Could not setup first cluster, either already exists or something is wrong with KinD"
  if [[ $CREATE_1 ]]; then
    echo "hi"
    exit
  fi
fi

if ! (kind create cluster --name "${CLUSTER_2_NAME}" --config "${CLUSTER_2_CONFIG}" -v4 --wait=180s); then
  echo "Could not setup second cluster, either already exists or something is wrong with KinD"
  if [[ $CREATE_2 ]]; then
    exit
  fi
fi

CLUSTER_1_CONTAINER_IP=$(docker inspect "${CLUSTER_1_NAME}-control-plane" --format "{{ .NetworkSettings.Networks.kind.IPAddress }}")
CLUSTER_2_CONTAINER_IP=$(docker inspect "${CLUSTER_2_NAME}-control-plane" --format "{{ .NetworkSettings.Networks.kind.IPAddress }}")

kind get kubeconfig --name "${CLUSTER_1_NAME}" --internal | sed "s/${CLUSTER_1_NAME}-control-plane/${CLUSTER_1_CONTAINER_IP}/g" > "${CLUSTER_1_KUBECONFIG}"
kind get kubeconfig --name "${CLUSTER_2_NAME}" --internal | sed "s/${CLUSTER_2_NAME}-control-plane/${CLUSTER_2_CONTAINER_IP}/g" > "${CLUSTER_2_KUBECONFIG}"

# connect clusters through same network
C1_POD_CIDR=$(KUBECONFIG="${CLUSTER_1_KUBECONFIG}" kubectl get node -ojsonpath='{.items[0].spec.podCIDR}')
echo "cluster 1 pod CIDR: ${C1_POD_CIDR}"
C2_POD_CIDR=$(KUBECONFIG="${CLUSTER_2_KUBECONFIG}" kubectl get node -ojsonpath='{.items[0].spec.podCIDR}')
echo "cluster 2 pod CIDR: ${C2_POD_CIDR}"
C1_SVC_CIDR=$(KUBECONFIG="${CLUSTER_1_KUBECONFIG}" kubectl cluster-info dump | sed -n 's/^.*--service-cluster-ip-range=\([^"]*\).*$/\1/p' | head -n 1)
C2_SVC_CIDR=$(KUBECONFIG="${CLUSTER_2_KUBECONFIG}" kubectl cluster-info dump | sed -n 's/^.*--service-cluster-ip-range=\([^"]*\).*$/\1/p' | head -n 1)

docker exec "${C1_NODE}" ip route add "${C2_POD_CIDR}" via "${CLUSTER_2_CONTAINER_IP}"
docker exec "${C1_NODE}" ip route add "${C2_SVC_CIDR}" via "${CLUSTER_2_CONTAINER_IP}"
docker exec "${C2_NODE}" ip route add "${C1_POD_CIDR}" via "${CLUSTER_1_CONTAINER_IP}"
docker exec "${C2_NODE}" ip route add "${C1_SVC_CIDR}" via "${CLUSTER_1_CONTAINER_IP}"