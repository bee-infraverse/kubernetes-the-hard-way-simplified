 #!/usr/bin/env bash

# Usage: ./wait-pvc-delete.sh <pvc-name> [namespace]
PVC_NAME="$1"
NAMESPACE="${2:-default}"

if [ -z "$PVC_NAME" ]; then
  echo "❌ Usage: $0 <pvc-name> [namespace]"
  exit 1
fi

# Get associated PV (might already be released)
PV_NAME=$(kubectl get pv -o jsonpath="{.items[?(@.spec.claimRef.name=='$PVC_NAME')].metadata.name}")
PV_NODE=$(kubectl get pv $PV_NAME -o jsonpath="{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}"
PV_PATH=$(kubectl get pv $PV_NAME -o jsonpath="{.spec.hostPath.path}")

echo "📦 Deleting PVC: $PVC_NAME"
kubectl delete pvc "$PVC_NAME" --namespace "$NAMESPACE"

echo "⏳ Waiting for PVC to be fully deleted..."
until ! kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" &>/dev/null; do
  sleep 1
done
echo "✅ PVC deleted."

if [ -n "$PV_NAME" ]; then
  echo "⏳ Waiting for PV '$PV_NAME' to be deleted..."
  kubectl delete pv "$PV_NAME" --wait=true 2>/dev/null || true
  until ! kubectl get pv "$PV_NAME" &>/dev/null; do
    sleep 1
  done
  echo "✅ PV deleted."
else
  echo "ℹ️ No bound PV found for PVC '$PVC_NAME'"
fi

# Get local path on node (only works for local provisioners like local-path)

if [ -n "$PV_PATH" ] && [ -n "$PV_NODE" ]; then
  echo "⏳ Waiting for path $PV_PATH to be removed on $PV_NODE..."
  until ! ssh root@"$PV_NODE" test -e "$PV_PATH"; do
    sleep 1
  done
  echo "✅ Volume path removed from node."
else
  echo "⚠️ Volume path not found or node not detected. Skipping path check."
fi
