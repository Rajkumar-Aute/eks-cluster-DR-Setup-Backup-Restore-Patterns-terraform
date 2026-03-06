#!/bin/bash

NAMESPACE="demo-app"

echo "Creating namespace: $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying Stateful Nginx with gp2 StorageClass..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: nginx-storage
      volumes:
      - name: nginx-storage
        persistentVolumeClaim:
          claimName: nginx-pvc
EOF

echo "Waiting for the Nginx pod to become ready..."
kubectl rollout status deployment/nginx-deployment -n $NAMESPACE

POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=nginx -o jsonpath='{.items[0].metadata.name}')

echo "Writing test data to the persistent volume..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh -c 'echo "<h1>Disaster Recovery Validation</h1><p>This data originated in the primary cluster and survived the failover.</p>" > /usr/share/nginx/html/index.html'

echo "Deployment complete!"