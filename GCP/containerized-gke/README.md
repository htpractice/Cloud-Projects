# LookMyShow on GKE (Containerized)

## Overview
This folder contains everything you need to deploy the LookMyShow Flask app as a containerized service on Google Kubernetes Engine (GKE). This approach is fully cloud-native, scalable, and production-ready.

---

## Prerequisites
- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)
- A GKE cluster (create with `gcloud container clusters create ...`)
- Cloud SQL instance (see `../infra/database-scaling.tf` for setup)

---

## Steps

### 1. Build & Push the Docker Image
```sh
# Set your project ID
export PROJECT_ID=your-gcp-project
# Authenticate Docker to GCR
gcloud auth configure-docker
# Build the image
cd GCP/containerized-gke
DOCKER_BUILDKIT=1 docker build -t gcr.io/$PROJECT_ID/lookmyshow-app:latest .
# Push to Google Container Registry
docker push gcr.io/$PROJECT_ID/lookmyshow-app:latest
```

### 2. Create Kubernetes Secrets and ConfigMap
- Edit `k8s-secrets-configmap.yaml` to set your DB credentials and host.
- (Recommended) Create the DB password secret securely:
  ```sh
  kubectl create secret generic lookmyshow-db-secret \
    --from-literal=DB_USER=lookmyshow_app \
    --from-literal=DB_PASSWORD=YOUR_DB_PASSWORD \
    --from-literal=DB_NAME=eventsdb
  ```
- Or apply the file:
  ```sh
  kubectl apply -f k8s-secrets-configmap.yaml
  ```

### 3. Add Cloud SQL Auth Proxy Service Account Secret
- Create a service account key with Cloud SQL Client role.
- Store it as a Kubernetes secret:
  ```sh
  kubectl create secret generic cloudsql-sa-key --from-file=service_account.json=PATH_TO_KEY.json
  ```

### 4. Edit Kubernetes Manifest
- Open `k8s-deployment.yaml`
- Replace `YOUR_PROJECT_ID`, `YOUR_REGION`, `YOUR_INSTANCE_ID` in the proxy command.
- The app will connect to the DB via `localhost:5432` (the proxy sidecar).

### 5. Deploy to GKE
```sh
kubectl apply -f k8s-deployment.yaml
```

### 6. Get the LoadBalancer IP
```sh
kubectl get service lookmyshow-service
```
- Access your app at `http://<EXTERNAL-IP>`

---

## Environment Variables & Security
- **DB credentials** are injected via Kubernetes Secret.
- **DB host** is injected via ConfigMap (set to `localhost` if using the proxy).
- **Cloud SQL Auth Proxy** runs as a sidecar for secure DB access.
- **Service Account Key** is mounted as a secret volume for the proxy.

---

## Cleanup
```sh
kubectl delete -f k8s-deployment.yaml
kubectl delete -f k8s-secrets-configmap.yaml
kubectl delete secret cloudsql-sa-key
```

---

## Best Practices
- **Never commit real secrets to git!** Use `kubectl create secret ...` in CI/CD or manually.
- **Scaling:** Adjust `replicas` in the Deployment as needed.
- **Monitoring:** Use GKE/Stackdriver for logs and metrics.
- **Cloud SQL Auth Proxy:** Ensures secure, authorized DB access from GKE.

---

## Reference
- Original Terraform infra: `../infra/`
- App source: `../website/`

--- 