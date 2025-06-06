# LookMyShow Infrastructure as Code (Terraform)

## Overview
This folder contains the complete, production-ready Terraform code for deploying the LookMyShow 3-tier architecture on Google Cloud Platform (GCP). All resources are fully dynamic and interconnected, allowing you to reference outputs (such as VM IP, Load Balancer IP, and DB connection info) in other modules or scripts.

---

## Structure & Files

| File                          | Purpose                                                      |
|-------------------------------|--------------------------------------------------------------|
| `database-scaling.tf`         | Cloud SQL (HA), read replicas, backups, Secret Manager, VPC  |
| `load-balancer-autoscaling.tf`| Global HTTP(S) LB, autoscaling MIG, firewall, monitoring     |
| `app-engine.tf`               | App Engine application/service deployment                    |
| `frontend-vm.tf`              | Compute Engine VM for frontend (Nginx/static, auto-deploys from GCS) |
| `website-static-bucket.tf`    | GCS bucket for static website files (automated deployment)   |
| `variables.tf` (optional)     | Centralized variable definitions (if you wish to add)        |
| `outputs.tf` (optional)       | Centralized outputs (if you wish to add)                     |

---

## Automated Static Website Deployment

- The static website (HTML/CSS/JS) is automatically deployed to the frontend VM using a GCS bucket and startup script.
- No manual file copy is needed after `terraform apply`—the site is always live and up-to-date.
- See `website-static-bucket.tf` for the bucket resource and instructions.

### How it Works
1. **Terraform creates a GCS bucket** for your static site (`website-static-bucket.tf`).
2. **You zip your website** and upload it to the bucket:
   ```sh
   cd website
   zip -r website.zip *
   gsutil cp website.zip gs://<bucket-name>/website.zip
   ```
3. **The VM's startup script** (in `frontend-vm.tf`) downloads and unzips the site from GCS on boot.
4. **Nginx is configured automatically** to serve the site.

### Result
- After `terraform apply`, your frontend VM will always have the latest static site deployed and ready, with no manual steps.

---

## Deployment Instructions

1. **Set up your environment:**
   - Install [Terraform](https://www.terraform.io/downloads.html)
   - Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)
   - Authenticate: `gcloud auth application-default login`
   - Set your project: `gcloud config set project <YOUR_PROJECT_ID>`

2. **Initialize Terraform:**
   ```sh
   cd infra
   terraform init
   ```

3. **Prepare and upload your static website:**
   - Zip your website files:
     ```sh
     cd ../website
     zip -r website.zip *
     gsutil cp website.zip gs://<bucket-name>/website.zip
     ```
   - Replace `<bucket-name>` with the value of `website_bucket` (default: `lookmyshow-website-static`).

4. **Review/override variables:**
   - Default variables are set in each `.tf` file (e.g., `region`, `zone`, `environment`).
   - To override, use a `terraform.tfvars` file or `-var` flags:
     ```sh
     terraform plan -var="project_id=your-gcp-project" -var="region=us-central1"
     ```

5. **Plan the deployment:**
   ```sh
   terraform plan -out=tfplan
   ```

6. **Apply the deployment:**
   ```sh
   terraform apply tfplan
   ```

7. **Check outputs:**
   - After apply, Terraform will print dynamic outputs such as:
     - `load_balancer_ip` and `load_balancer_url` (public entrypoint)
     - `primary_instance_connection_name` (Cloud SQL connection)
     - `database_name`, `app_username`, `password_secret_name`
     - `frontend_vm_ip` (if you add an output for the VM's IP)
   - You can reference these outputs in other modules or scripts.

8. **Destroy the deployment:**
   ```sh
   terraform destroy
   ```

---

## Dynamic Interconnection & Outputs
- All major resources export outputs (see each `.tf` file's `output` blocks).
- Example: The VM and App Engine can use the DB connection name and secret from Cloud SQL outputs.
- The Load Balancer's IP/URL is available as an output for DNS or documentation.
- You can use these outputs in other Terraform modules via `terraform_remote_state` or in CI/CD scripts.

---

## Best Practices & Troubleshooting
- **State Management:** Use remote state (e.g., GCS backend) for team deployments.
- **Secrets:** All DB credentials are stored in Secret Manager, not in code.
- **Scaling:** Adjust autoscaler and instance group settings as needed.
- **App Engine:** Make sure your app is packaged and uploaded to the referenced GCS bucket.
- **Frontend VM:**
  - The static site is always deployed from GCS—no manual copy needed.
  - If the site does not appear, check the VM logs for gsutil/unzip errors and ensure `website.zip` is present in the bucket.
  - You can update the site at any time by uploading a new `website.zip` to the bucket and recreating the VM (or using a rolling update).
- **Quotas:** Ensure your GCP project has sufficient quota for all resources.
- **Cleanup:** Always run `terraform destroy` to avoid unexpected charges.

---

## Extending & Integrating
- Add more outputs to `outputs.tf` for any resource you want to reference elsewhere.
- Use variables for all configurable values for maximum flexibility.
- Integrate with CI/CD by running `terraform plan` and `terraform apply` in your pipeline.

---

## Questions?
If you have any issues or want to extend the setup, check the comments in each `.tf` file or open an issue in your repository. 