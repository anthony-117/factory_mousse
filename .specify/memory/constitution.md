# Factory Mousse Constitution

Factory Mousse holds the infrastructure and the releases of TravelGenie, a USEK final-year project (defence around
June 2027). It runs the `pamplemousse` backend on an Oracle Always Free server and the `chocomousse` web app on
Firebase Hosting. It holds no application code.

## Core Principles

### I. Versions Are the Only Way to Deploy

- What is live MUST be what `versions.yaml` says, and a version MUST change only through a pull request.
- This repo MUST deploy the builds each app repo published for a tag, and MUST NOT rebuild them.
- A backend deploy MUST use the image's digest, so that moving a tag can't change what runs.
- Rollback MUST be possible by reverting the pull request. A release MUST NOT change stored data in a way the
  previous version can't read.

### II. Infrastructure Changes Are Separate and Deliberate (NON-NEGOTIABLE)

- A version change MUST NOT run OpenTofu. Infrastructure changes have their own pipeline.
- An apply MUST wait for the owner's approval, after a plan the owner can read.
- Infrastructure is written in Terraform's language and run with OpenTofu, because HashiCorp blocks Terraform's
  downloads and registry from the owner's region.
- The server and the Firebase project MUST keep `prevent_destroy`. Recreating the server can fail for lack of
  free capacity. Removing the protection MUST be its own pull request, saying why.

### III. No Secrets in the Repo

- This repo is public. Secrets MUST live in GitHub secrets, and infrastructure state in Oracle Object Storage.
- Secrets, state and credentials MUST NOT be committed, printed in logs or stored as build artifacts.
- The apps MUST NOT receive secrets at build time; `app.env` ships to browsers.

### IV. Every Change Is Checked

- `scripts/check.sh` MUST pass in CI and in the pre-push hook. It covers OpenTofu formatting and validation,
  the Compose file, the Caddyfile and the shell scripts.
- The hook MUST NOT be bypassed without the owner's say-so.
- A backend deploy MUST pass a health check, and MUST go back to the previous image if it fails.

### V. Low Cost First

- The project MUST run at about $0 during development. A paid service, or one requiring a billing card, MUST NOT be
  added without the owner's explicit approval, and this includes Firebase's Blaze plan.
- Oracle resources MUST stay within the Always Free limits. Load MUST NOT be faked to avoid idle reclamation.

### VI. Simplicity

- Prefer the simplest setup that does the job: Docker Compose on one server until there is a reason for more.
- A new service, tool or platform, such as Kubernetes or a RAG service, MUST have an ADR first, and MUST fit the
  server's 2 OCPUs and 12 GB.

## Development Workflow

- `main` is protected: every change MUST go through a branch and a pull request, and CI MUST pass.
- A substantial change MUST have a spec in `specs/`, approved by the owner with its plan before work starts. Version
  changes and small fixes MAY skip the spec.
- Lasting decisions MUST be recorded as ADRs in `pamplemousse/docs/architecture/adr/`, the shared documentation.
- `docs/runbook.md` MUST change in the same pull request as anything it describes.

## Governance

- This constitution takes precedence over other practices. The app repos have their own constitutions.
- When principles conflict, the order is: III No Secrets, then V Low Cost, then II Infrastructure, then delivery speed.
- Only the owner approves amendments, through a pull request stating the reason.
- Versions follow semantic versioning: MAJOR removes or redefines a principle, MINOR adds or expands one, PATCH
  fixes wording.
- Every plan MUST pass the Constitution Check. Any justified violation MUST be recorded in the plan's Complexity
  Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-11-02 | **Last Amended**: 2026-11-02
