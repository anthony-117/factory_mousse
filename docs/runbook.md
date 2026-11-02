# Runbook

## First-time setup

Deployment stays off until steps 1 to 6 are done, so nothing fails in the meantime.

1. **Oracle account.** Create it, and choose the home region carefully: Always Free compute only exists there, and it can't be changed later.
2. **API key.** In the Oracle console, add an API key to your user. Note the tenancy OCID, user OCID, fingerprint and region, and keep the private key.
3. **State bucket.** Create a private Object Storage bucket named `terraform-state` with versioning on. Note the namespace shown on the bucket's page. Then, under your user, create a Customer Secret Key: it gives the access key and secret key OpenTofu uses for this bucket.
4. **Firebase service account.** In the Firebase console, under Project settings → Service accounts, generate a key. It needs the Firebase Admin and Service Usage Consumer roles.
5. **SSH key.** Create a key pair used only for deployments:
   ```bash
   ssh-keygen -t ed25519 -f factory_mousse_deploy -N ""
   ```
6. **GitHub settings.** Under Settings → Secrets and variables → Actions, add:

   | Secret | Value |
   |---|---|
   | `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT` | From step 2 |
   | `OCI_PRIVATE_KEY` | The private key from step 2 |
   | `STATE_ACCESS_KEY`, `STATE_SECRET_KEY` | The Customer Secret Key from step 3 |
   | `FIREBASE_SERVICE_ACCOUNT` | The JSON key from step 4 |
   | `SSH_PRIVATE_KEY` | The private key from step 5 |
   | `BACKEND_ENV` | The backend's `.env` content, including `CORS_ALLOWED_ORIGINS=https://travel-genie.sarl,https://travelgenie-1fdd1.web.app` |

   | Variable | Value |
   |---|---|
   | `OCI_REGION` | Your home region |
   | `STATE_BUCKET`, `STATE_NAMESPACE` | From step 3 |
   | `SSH_PUBLIC_KEY` | The public key from step 5 |

   Under Settings → Environments, create `infrastructure` with yourself as a required reviewer, and `production`.
7. **Create the infrastructure.** Set the variable `INFRA_ENABLED` to `true` and run the Infrastructure workflow. Read the plan, then approve the apply. If it fails with "out of host capacity", retry later or change `availability_domain_index`.
8. **Connect it.** Set the variable `SERVER_IP` from the workflow's output, and `API_DOMAIN` to `api.travel-genie.sarl`. In Cloudflare, add an `A` record for `api` pointing to the server's IP, set to "DNS only". It must exist before the first release, because Caddy needs it to get the HTTPS certificate.
9. **Publish the apps.** Tag `v1.0.0` in `pamplemousse` and `chocomousse`. In `pamplemousse`'s package settings on GitHub, make the `pamplemousse` image public, because the server pulls it without logging in.
10. **Turn on releases.** Set the variable `DEPLOY_ENABLED` to `true` and run the Release workflow.
11. **Connect the web domain.** In the Firebase console, under Hosting, add `travel-genie.sarl` as a custom domain and `www.travel-genie.sarl` as a redirect to it. Add the records Firebase gives you in Cloudflare, set to "DNS only".

## Release and rollback

- **Release:** change `versions.yaml` through a pull request and merge it.
- **Rollback:** revert that pull request. The code goes back, but changes to stored data don't, so a release must not change data in a way the previous version can't read.
- **Failed backend deploy:** `deploy.sh` goes back to the previous image on its own, and the workflow fails without deploying the app.

## Keeping old and new compatible

The backend and the app deploy separately, and phones can keep an old app for months. `/api/v1` therefore has to stay backward compatible. Only web and backend are released from here; Android and iOS builds aren't.

## Server problems

- **Look at it:** log in with the deploy key as `ubuntu`, then go to `/opt/travelgenie` and run `docker compose --env-file release.env ps`, or `logs api`.
- **Reclaimed for being idle:** Oracle may reclaim a server when CPU, network and memory all stay under 20% for 7 days. Don't fake load to avoid this.
- **Lost server:** `prevent_destroy` stops OpenTofu from replacing it, so remove that line on purpose in a pull request, apply, and restore the line. Then update `SERVER_IP` and the `api` record in Cloudflare, and run the Release workflow.

## Not automated yet

- Firestore, Auth and file storage: they depend on the database decision and on the Blaze plan, which needs a billing card.
- DNS records in Cloudflare, which are set by hand.
- A check that the two app versions are compatible before deploying.
- Kubernetes and ArgoCD, a possible later upgrade.
