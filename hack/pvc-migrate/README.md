# PVC Migrate 

## Same Namespace but different stroage class possible

This script facilitates the migration of data from one Persistent Volume Claim (PVC) to another within a Kubernetes cluster. 
It uses a Kubernetes Job to perform the migration using `rsync`.

- https://justyn.io/til/migrate-kubernetes-pvc-to-another-pvc/

```shell
# Create PVC
PVCSRC_NAME=source-pvc
PVCDST_NAME=cloned-pvc
NAMESPACE=default

make build
# or
make build IMAGE=myrepo/myimage TAG=dev
make push IMAGE=myrepo/myimage TAG=dev

./pvc-migrate.sh $PVCSRC_NAME $PVCDST_NAME $NAMESPACE
```

## Data Migration between Persistent Volume Claims (PVCs)

- Create an original PVC
- Create a VolumeSnapshot of that PVC
- Create a new PVC from the snapshot

⚠️ This assumes your cluster has:
- A CSI driver that supports volume snapshots (e.g. OpenEBS, Longhorn, etc.)
- VolumeSnapshotClass already configured
- snapshot.storage.k8s.io CRDs installed (check with kubectl api-resources | grep snapshot)

```shell
# longhorn or ceph
CSI-CLASS=
CSI-SNAP-CLASS=

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ${CSI-CLASS}
  resources:
    requests:
      storage: 1Gi
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: source-pod
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["/bin/sh", "-c", "while true; do date && sleep 5; done"]
      volumeMounts:
        - mountPath: "/data"
          name: source-vol
  volumes:
    - name: source-vol
      persistentVolumeClaim:
        claimName: source-pvc
EOF

cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: source-pvc-snapshot
spec:
  volumeSnapshotClassName: ${CSI-SNAP-CLASS}
  source:
    persistentVolumeClaimName: source-pvc
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ${CSI-CLASS}
  resources:
    requests:
      storage: 1Gi
  dataSource:
    name: source-pvc-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-clone
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
        - mountPath: "/data"
          name: test-vol
  volumes:
    - name: test-vol
      persistentVolumeClaim:
        claimName: cloned-pvc
EOF
```
    
## General pv-migrate

- https://github.com/utkuozdemir/pv-migrate

## Use velero for migration

- https://velero.io/docs/v1.10/backup-migration/

Regards,
Peter