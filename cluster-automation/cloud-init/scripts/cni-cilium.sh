#!/usr/bin/env bash
set -e
PUBLIC_IPv4=$(curl -s https://metadata.platformequinix.com/metadata | jq -r '.network.addresses | map(select(.public==true and .management==true)) | first | .address')

helm repo add cilium https://helm.cilium.io/

helm template cilium/cilium  \
		--version 1.10.2 \
		--namespace kube-system \
		--set image.repository=quay.io/cilium/cilium \
		--set global.ipam.mode=cluster-pool \
		--set global.ipam.operator.clusterPoolIPv4PodCIDR=192.168.0.0/16 \
		--set global.ipam.operator.clusterPoolIPv4MaskSize=23 \
		--set global.nativeRoutingCIDR=192.168.0.0/16 \
		--set global.endpointRoutes.enabled=true \
		--set global.hubble.relay.enabled=true \
		--set global.hubble.enabled=true \
		--set global.hubble.listenAddress=":4244" \
		--set global.hubble.ui.enabled=true \
    --set kubeProxyReplacement=probe \
    --set k8sServiceHost=${PUBLIC_IPv4} \
    --set k8sServicePort=6443 \
		> /tmp/cilium.yaml

kubectl --kubeconfig=/etc/kubernetes/admin.conf apply --wait -f /tmp/cilium.yaml
