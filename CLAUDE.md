# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is the official Helm chart for **Cognigy.AI**, an enterprise conversational-automation platform. It is a pure Helm chart (no application source code) that deploys ~50+ Cognigy microservices plus their infrastructure dependencies onto Kubernetes. `Chart.yaml` drives versioning (current line: `2026.x.y`) and pulls in subcharts: `traefik` (+ `traefikInternal` alias), `qdrant`, Bitnami `redis` (aliased twice as `redisHa` and `redisPersistentHa`), Zalando `postgres-operator`, `keda`, and `nats` (aliased `natsInternal`). Most dependencies are conditionally enabled via `<name>.enabled` in `values.yaml`.

Releases are cut from git tags via `.azuredevops/release-pipeline.yaml`, which packages the chart and pushes it to `oci://cognigy.azurecr.io/helm/cognigy.ai`. Do not hand-edit release artifacts — bump `Chart.yaml` `version`/`appVersion` and let the pipeline publish.

## Common commands

Helm development loop (templates don't compile without dependencies):

```bash
helm dependency update                                                   # populate charts/
helm lint .                                                              # schema + template sanity
helm lint . --values values-local.yaml                                   # lint against a real values file
helm template cognigy-ai . --values values-local.yaml                    # render everything
helm template cognigy-ai . -s templates/service-ai/service-ai.yaml \
  --values values-local.yaml                                             # render one file
helm template cognigy-ai . --values values-local.yaml > values-local.out.yaml   # pattern used in-repo for diffs
```

`values.schema.json` is validated on `helm install/lint/template`; schema changes must accompany values changes that introduce new required top-level keys.

## Layout

- **`values.yaml`** (~200KB) — authoritative defaults. Includes every microservice's image reference, so downstream users are explicitly told in `README.md` not to copy it wholesale; instead copy `values_prod_<aws|azure|generic>.yaml` and override only what's needed.
- **`values-local.yaml`** — developer-only overrides for a local MicroK8s-style deployment (`cloud.provider: local-microk8s`). Not shipped to users. `values-local.out.yaml` is the rendered output, kept in-tree as a diff reference — regenerate it when template output changes materially.
- **`templates/`** — one directory per microservice (`service-ai/`, `service-api/`, `service-nlp-*`, `agent-asssit-*`, etc.) plus cross-cutting dirs: `common/` (PVC, HPA, priority-class, secret generators), `common-secrets/`, `configurations/`, `ingress/`, `middleware/`, `insights/`, `microfrontends/`, `pod-monitors/`, `stateful-deployments/`, and cloud-specific `aws/`, `azure/`, `local/`.
- **`templates/_helpers.tpl`** — large (~570 line) collection of shared template functions. New services should reuse these rather than hand-rolling labels, pull-secret blocks, node options, etc.
- **`templates/_images.tpl`, `templates/_insights.tpl`** — specialised helpers (image reference rendering, insights service plumbing).
- **`templates/common/secrets-generate.tpl`** and **`templates/dbinit-generate/`** — generate connection-string secrets at install time. `scripts/dbinit-generate.sh` / `dbinit-generate-atlas.sh` back these; `scripts/backup_cognigy_ai_secrets.sh` is referenced in README as the recommended secret-backup tool.
- **`CHANGELOG/CHANGELOG-<version>.md`** — one file per release version (`2025.x.0`, `2026.x.0`). When bumping `Chart.yaml` version, add a matching changelog file. `HINTS-4.*.md` files document upgrade hints for pre-2025 versions.
- **`charts/`** — tarballed dependencies checked in (populated by `helm dependency update`).

## Conventions worth knowing

- **Secret name resolution is centralised.** Templates rarely hard-code secret names. Instead they call the helper pattern `include "common.secretName.render" (dict "existingSecret" $.Values.<path>.existingSecret "defaultSecret" "<fallback>")`. When adding a new secret consumer, follow this so users can override via `existingSecret` everywhere. See the preamble of `templates/service-ai/service-ai.yaml` for the canonical block of lookups.
- **Deployments include `checksum/*` pod annotations** derived from referenced secrets/configmaps, so pods roll when secrets change. New deployments referencing secrets should follow the same pattern (see `service-ai.yaml`).
- **Services are scoped with `{{- with .Values.<serviceName> }} ... {{- end }}`** to reduce `.Values.serviceAi.*` repetition inside the spec. Top-level references from inside `with` use `$` (e.g. `$.Values`, `$.Release.Namespace`).
- **`owner-team: <metal>` label** on deployments (`aluminium`, etc.) — preserve it when editing or adding deployments; it's how SRE attributes services to teams.
- **Conditional rendering keys** like `$.Values.hpa.enabled`, `$.Values.hpa.services.<name>.enabled`, `$.Values.natsInternal.enabled`, `$.Values.niceCXOne.enabled`, `$.Values.llmGateway.enabled`, `$.Values.knowledgeSearch.enabled`, `$.Values.cognigyAgentAssist.enabled` gate large blocks — when adding a feature, mirror the existing enable-flag structure instead of introducing a new pattern.
- **HPA vs. replicas.** Replica counts are suppressed when HPA is managing a service: `if not (and ($.Values.hpa.enabled) ($.Values.hpa.removeReplicas) ($.Values.hpa.services.<name>.enabled))`. Match this guard on any new horizontally-scaled deployment.
- **Per-cloud templates.** Logic that only applies to AWS/Azure/local goes under `templates/aws/`, `templates/azure/`, `templates/local/` and is gated on `.Values.cloud.provider`. Do not add cloud-specific conditionals inside generic service templates.

## PRs and workflow

- This repo uses **Azure DevOps** as the primary origin (see `.azuredevops/`); GitHub is a mirror used by the release pipeline. Recent commits show the Merged-PR style (`Merged PR 59902: AB#130062 feat(helm): ...`). New PR titles should follow `AB#<work-item> <conventional-commit>(<scope>): <summary>`.
- PR template (`.azuredevops/pull_request_template.md`) is a security checklist covering new ingresses, new services/NodePort, and annotation changes — fill it out.
- `.github/agents/implementation-plan.agent.md` defines the "Implementation Plan Generation Mode" prompt used in this repo. If asked to produce an implementation plan, follow that template structure and save files under `/plan/`.
