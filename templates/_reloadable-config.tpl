{{/*
Name of the per-service ServiceAccount/Role/RoleBinding.
Prefixed with the release name since these objects are not otherwise disambiguated
when multiple Cognigy.AI releases share a cluster (serviceName is cluster unique).
*/}}
{{- define "cognigy-ai.reloadableConfig.restartCoordinator.name" -}}
{{- printf "%s-%s" .context.Release.Name .serviceName -}}
{{- end -}}

{{/*
Name of the ServiceAccount that should be granted restart-coordinator permissions.
Resolves to `existingServiceAccount` when the caller already runs the service under
its own ServiceAccount, otherwise falls back to the dedicated auto-created one.
*/}}
{{- define "cognigy-ai.reloadableConfig.restartCoordinator.serviceAccountName" -}}
{{- if .existingServiceAccount -}}
{{- .existingServiceAccount -}}
{{- else -}}
{{- include "cognigy-ai.reloadableConfig.restartCoordinator.name" . -}}
{{- end -}}
{{- end -}}

{{/*
Dedicated ServiceAccount for a service's reloadable-config restart-coordinator
identity. Rendered only when the caller has no `existingServiceAccount` — see
`.rbac` below, which is the entry point callers should use instead of this directly.
*/}}
{{- define "cognigy-ai.reloadableConfig.restartCoordinator.serviceAccount" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "cognigy-ai.reloadableConfig.restartCoordinator.name" . | quote }}
  namespace: {{ .context.Release.Namespace | quote }}
  {{- if .ownerTeam }}
  labels:
    owner-team: {{ .ownerTeam }}
  {{- end }}
{{- end -}}

{{/*
Role + RoleBinding granting a service's reloadable-config library permission to
patch its own Deployment's pod-template annotation, so it can trigger a
K8s-native rolling restart for restart-required config keys. See
github.com/Cognigy/reloadable-config docs/02-adoption.md.

`serviceName` must be the exact Deployment object name (unprefixed) so the Role's
`resourceNames` scoping matches the real Deployment being patched. The RoleBinding
subject is `.serviceAccountName` above, i.e. `existingServiceAccount` if set.
*/}}
{{- define "cognigy-ai.reloadableConfig.restartCoordinator.roleAndBinding" -}}
{{- $name := include "cognigy-ai.reloadableConfig.restartCoordinator.name" . }}
{{- $saName := include "cognigy-ai.reloadableConfig.restartCoordinator.serviceAccountName" . }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $name | quote }}
  namespace: {{ .context.Release.Namespace | quote }}
  {{- if .ownerTeam }}
  labels:
    owner-team: {{ .ownerTeam }}
  {{- end }}
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  resourceNames: [{{ .serviceName | quote }}]
  verbs: ["get", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $name | quote }}
  namespace: {{ .context.Release.Namespace | quote }}
  {{- if .ownerTeam }}
  labels:
    owner-team: {{ .ownerTeam }}
  {{- end }}
subjects:
- kind: ServiceAccount
  name: {{ $saName | quote }}
  apiGroup: ""
roleRef:
  kind: Role
  name: {{ $name | quote }}
  apiGroup: rbac.authorization.k8s.io
{{- end -}}

{{/*
Entry point: renders the dedicated ServiceAccount (unless `existingServiceAccount`
is set, in which case it's skipped) plus the Role/RoleBinding attached to whichever
ServiceAccount applies. Pass `ownerTeam` to label the generated resources the same
way as the owning Deployment. Pass `existingServiceAccount` when the service already
runs under its own ServiceAccount so this only attaches the new Role to it, e.g.:

  {{ include "cognigy-ai.reloadableConfig.restartCoordinator.rbac"
       (dict "serviceName" "service-xyz"
             "existingServiceAccount" .Values.serviceXyz.serviceAccountName
             "ownerTeam" "aluminium"
             "context" $) }}

IMPORTANT when adopting this on a service that already has a `serviceAccountName`
values option: the Deployment's own `serviceAccountName:` field must ALSO switch to
`cognigy-ai.reloadableConfig.restartCoordinator.serviceAccountName` (same args, minus
`ownerTeam`) unconditionally. Do not keep an old `{{- if .serviceAccountName }}` guard
around it — this helper never returns empty, so the guard's only remaining effect is
to silently drop `serviceAccountName:` (and hence the RBAC binding) whenever the value
is unset, which is the common case. A leftover guard renders clean, deploys clean, and
the restart-coordinator's self-patch then 403s under the `default` ServiceAccount with
no visible error.
*/}}
{{- define "cognigy-ai.reloadableConfig.restartCoordinator.rbac" -}}
{{- if not .existingServiceAccount -}}
{{- include "cognigy-ai.reloadableConfig.restartCoordinator.serviceAccount" . }}
---
{{- end }}
{{- include "cognigy-ai.reloadableConfig.restartCoordinator.roleAndBinding" . }}
{{- end -}}
