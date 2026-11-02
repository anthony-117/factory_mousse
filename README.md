# factory_mousse — TravelGenie infrastructure and releases

This repo says what runs, where it runs and how it gets deployed. It holds no application code.

| Path | Purpose |
|---|---|
| `versions.yaml` | The live version of each app |
| `infra/oracle/` | Network, firewall and the Always Free ARM server |
| `infra/firebase/` | The existing Firebase project and hosting site |
| `deploy/` | Docker Compose, Caddy (HTTPS) and the script that starts a version on the server |
| `.github/workflows/` | `release.yml` deploys versions, `infra.yml` changes infrastructure, `ci.yml` checks the repo |
| `.specify/` | Spec Kit and the constitution |
| `docs/runbook.md` | First-time setup, releases, rollback and recovery |

The apps live in [`pamplemousse`](https://github.com/anthony-117/pamplemousse) (backend) and [`chocomousse`](https://github.com/anthony-117/chocomousse) (app). The decision is recorded in [ADR 0015](https://github.com/anthony-117/pamplemousse/blob/main/docs/architecture/adr/0015-factory-mousse-and-oracle-hosting.md), and this repo's rules are in the [constitution](.specify/memory/constitution.md).

## Releasing
1. Tag the app repo, for example `v1.2.0`. Its release workflow tests and publishes that version.
2. Change the version in `versions.yaml` through a pull request here.
3. Merge. The backend deploys first, with a health check that goes back to the previous version on failure, and then the app.

To roll back, revert that pull request.

## Checks
```bash
sh scripts/install-hooks.sh
```
```bash
sh scripts/check.sh
```
The pre-push hook and CI run the same script, which needs [OpenTofu](https://opentofu.org/docs/intro/install/) and Docker and touches no cloud account.

The infrastructure is written in Terraform's language and run with OpenTofu, its open-source fork, because HashiCorp blocks Terraform's downloads and registry from the owner's region.
