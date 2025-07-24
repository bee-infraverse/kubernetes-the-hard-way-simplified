#!/bin/bash

set -exu

PVCSRC_NAME=$1
PVCDST_NAME=$2
NAMESPACE=${3:-default}

if [ -z "$PVCSRC_NAME" ] || [ -z "$PVCDST_NAME" ]; then
  echo "Usage: $0 <source-pvc-name> <destination-pvc-name> [namespace]"
  exit 1
fi

if kubectl get pvc "$PVCSRC_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "✅ PVC '$PVCSRC_NAME' exists."
else
  echo "❌ PVC '$PVCSRC_NAME' does not exist in namespace '$NAMESPACE'."
  exit 2
fi

if kubectl get pvc "$PVCDST_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "✅ PVC '$PVCDST_NAME' exists."
else
  echo "❌ PVC '$PVCDST_NAME' does not exist in namespace '$NAMESPACE'."
  exit 2
fi

echo "Starting migration from $PVCSRC_NAME to $PVCDST_NAME"

cat << EOF | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-pv-$PVCSRC_NAME
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: bee-infraverse/pvc-migrate:latest
        volumeMounts:
        - mountPath: /src_vol
          name: src
          readOnly: true
        - mountPath: /dst_vol
          name: dst
      restartPolicy: Never
      volumes:
      - name: src
        persistentVolumeClaim:
          claimName: $PVCSRC_NAME
      - name: dst
        persistentVolumeClaim:
          claimName: $PVCDST_NAME
  backoffLimit: 1
EOF
kubectl wait --for=condition=complete --timeout=60s job/migrate-pv-$PVCSRC_NAME
kubectl delete job migrate-pv-$PVCSRC_NAME

echo "Migration completed successfully from $PVCSRC_NAME to $PVCDST_NAME"
echo "You can now use the new PVC: $PVCDST_NAME"
echo "Remember to update your deployments or statefulsets to use the new PVC."
echo "Cleanup completed."
