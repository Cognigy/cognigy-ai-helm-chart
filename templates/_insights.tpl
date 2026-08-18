{{/*
Return host name of the CubeJS Postgres database
Usage:
{{- include "cognigy-ai.cubejs.postgresql.host" $ }}
*/}}
{{- define "cognigy-ai.cubejs.postgresql.host" -}}
  {{- $postgresqlHost := "" -}}

  {{- if .Values.cubejs.postgresql.readReplica.useReadReplica -}}
    {{- $postgresqlHost = .Values.cubejs.postgresql.readReplica.host -}}
  {{- else -}}
    {{- $postgresqlHost = .Values.cubejs.postgresql.host -}}
  {{- end -}}

  {{- printf "%s" (include "common.tplvalues.render" (dict "value" $postgresqlHost "context" $)) -}}
{{- end -}}

{{/*
Return the effective provider for Insights Postgres: "operator", "external", or "disabled".
If insights.postgresql.provider is unset, derives from pgoperator.enabled for backwards compat.
DEPRECATED: set insights.postgresql.provider explicitly. Auto-derive removed in 2027.x.
Usage:
{{- include "cognigy-ai.insights.postgresql.provider" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.provider" -}}
  {{- $provided := .Values.insights.postgresql.provider -}}
  {{- if $provided -}}
    {{- $provided -}}
  {{- else -}}
    {{- ternary "operator" "disabled" .Values.pgoperator.enabled -}}
  {{- end -}}
{{- end -}}

{{/*
Returns "true" when Insights Postgres is active (operator or external), empty string when disabled.
Usage:
{{- if include "cognigy-ai.insights.postgresql.enabled" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.enabled" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" . -}}
  {{- if ne $p "disabled" -}}true{{- end -}}
{{- end -}}

{{/*
EXPERIMENTAL: resolve whether an Insights Postgres consumer should redirect to the read replica.
True when EITHER the provider-level readReplica.useReadReplica flag is true (global override for
every consumer) OR the calling service's own useReadReplica flag is true. This mechanism is under
active development — enabling it may not yet behave correctly in every scenario. Validate in a
non-production environment first, and please report any issues you run into.
Usage (the useReadReplica value comes from the calling service's own values block):
{{- include "cognigy-ai.insights.postgresql.useReadReplica" (dict "context" $ "useReadReplica" $.Values.serviceCollector.useReadReplica) }}
*/}}
{{- define "cognigy-ai.insights.postgresql.useReadReplica" -}}
  {{- $ctx := index . "context" -}}
  {{- $serviceFlag := index . "useReadReplica" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" $ctx -}}
  {{- $globalFlag := $ctx.Values.insights.postgresql.cluster.readReplica.useReadReplica -}}
  {{- if eq $p "external" -}}
    {{- $globalFlag = $ctx.Values.insights.postgresql.external.readReplica.useReadReplica -}}
  {{- end -}}
  {{- if or $globalFlag $serviceFlag -}}true{{- end -}}
{{- end -}}

{{/*
Return the Postgres host for Insights consumers.
Returns the read-replica host when useReadReplica resolves to true, otherwise the primary.
Use this for services with a single host variable (primary-or-replica pattern).
External mode: uses insights.postgresql.external.host (or readReplica.host when enabled).
Operator mode: uses insights.postgresql.cluster.host (or readReplica.host when enabled).
EXPERIMENTAL: the read-replica redirection path is under active development — enabling
useReadReplica may not yet behave correctly in every scenario. Validate in a non-production
environment first, and please report any issues you run into.
Usage (pass the calling service's own useReadReplica flag):
{{- include "cognigy-ai.insights.postgresql.host" (dict "context" $ "useReadReplica" $.Values.serviceCollector.useReadReplica) }}
*/}}
{{- define "cognigy-ai.insights.postgresql.host" -}}
  {{- $ctx := index . "context" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" $ctx -}}
  {{- $useReplica := include "cognigy-ai.insights.postgresql.useReadReplica" . -}}
  {{- if eq $p "external" -}}
    {{- if and $useReplica $ctx.Values.insights.postgresql.external.readReplica.host -}}
      {{- tpl $ctx.Values.insights.postgresql.external.readReplica.host $ctx -}}
    {{- else -}}
      {{- required "insights.postgresql.external.host is required when provider=external" $ctx.Values.insights.postgresql.external.host -}}
    {{- end -}}
  {{- else -}}
    {{- if $useReplica -}}
      {{- tpl $ctx.Values.insights.postgresql.cluster.readReplica.host $ctx -}}
    {{- else -}}
      {{- tpl $ctx.Values.insights.postgresql.cluster.host $ctx -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return the primary Postgres host for Insights consumers — always the primary, never the read-replica.
Use this for services that expose separate POSTGRES_HOST (primary) and
INSIGHTS_POSTGRES_DB_REPLICA_HOST (replica) variables.
External mode: uses insights.postgresql.external.host.
Operator mode: uses insights.postgresql.cluster.host.
Usage:
{{- include "cognigy-ai.insights.postgresql.primary.host" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.primary.host" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" . -}}
  {{- if eq $p "external" -}}
    {{- required "insights.postgresql.external.host is required when provider=external" .Values.insights.postgresql.external.host -}}
  {{- else -}}
    {{- tpl .Values.insights.postgresql.cluster.host . -}}
  {{- end -}}
{{- end -}}

{{/*
Return the read-replica Postgres host for Insights consumers, or empty string when not enabled.
External mode: returns insights.postgresql.external.readReplica.host when useReadReplica resolves to true.
Operator mode: returns insights.postgresql.cluster.readReplica.host when useReadReplica resolves to true.
EXPERIMENTAL: the read-replica redirection path is under active development — enabling
useReadReplica may not yet behave correctly in every scenario. Validate in a non-production
environment first, and please report any issues you run into.
Usage (pass the calling service's own useReadReplica flag):
{{- include "cognigy-ai.insights.postgresql.replica.host" (dict "context" $ "useReadReplica" $.Values.serviceCollector.useReadReplica) }}
*/}}
{{- define "cognigy-ai.insights.postgresql.replica.host" -}}
  {{- $ctx := index . "context" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" $ctx -}}
  {{- $useReplica := include "cognigy-ai.insights.postgresql.useReadReplica" . -}}
  {{- if eq $p "external" -}}
    {{- if and $useReplica $ctx.Values.insights.postgresql.external.readReplica.host -}}
      {{- tpl $ctx.Values.insights.postgresql.external.readReplica.host $ctx -}}
    {{- end -}}
  {{- else -}}
    {{- if $useReplica -}}
      {{- tpl $ctx.Values.insights.postgresql.cluster.readReplica.host $ctx -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return the Postgres port for Insights consumers.
Usage:
{{- include "cognigy-ai.insights.postgresql.port" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.port" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" . -}}
  {{- if eq $p "external" -}}
    {{- .Values.insights.postgresql.external.port -}}
  {{- else -}}
    {{- .Values.insights.postgresql.cluster.port -}}
  {{- end -}}
{{- end -}}

{{/*
Return the sslmode for Insights Postgres consumers.
Usage:
{{- include "cognigy-ai.insights.postgresql.sslmode" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.sslmode" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" . -}}
  {{- if eq $p "external" -}}
    {{- .Values.insights.postgresql.external.sslmode -}}
  {{- else -}}
    {{- .Values.insights.postgresql.cluster.sslmode | default "require" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the Secret name holding app-user credentials for Insights Postgres.
Works for both operator mode (Zalando-shaped default) and external mode (plain secret name).
Usage:
{{- include "cognigy-ai.insights.postgresql.secret" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.secret" -}}
  {{- include "common.secretName.render" (dict
    "existingSecret" (tpl .Values.insights.postgresql.auth.insightsUser.existingSecret .)
    "defaultSecret" "cognigy-insights-postgres-ha-insights") -}}
{{- end -}}

{{/*
Return the Secret name holding superuser credentials for Insights Postgres.
Used only by the pg-init Job in external mode.
Usage:
{{- include "cognigy-ai.insights.postgresql.superuser.secret" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.superuser.secret" -}}
  {{- include "common.secretName.render" (dict
    "existingSecret" (tpl .Values.insights.postgresql.auth.superUser.existingSecret .)
    "defaultSecret" "postgres-postgres-ha-insights") -}}
{{- end -}}

{{/*
Validate Insights Postgres configuration. Invoked unconditionally from NOTES.txt.
*/}}
{{- define "cognigy-ai.insights.postgresql.validate" -}}
  {{- $p := include "cognigy-ai.insights.postgresql.provider" . -}}
  {{- if and (eq $p "operator") (not .Values.pgoperator.enabled) -}}
    {{- fail "insights.postgresql.provider=operator requires pgoperator.enabled=true" -}}
  {{- end -}}
  {{- if eq $p "external" -}}
    {{- if not .Values.insights.postgresql.external.host -}}
      {{- fail "insights.postgresql.external.host is required when provider=external" -}}
    {{- end -}}
    {{- $insightsSecret := tpl .Values.insights.postgresql.auth.insightsUser.existingSecret . -}}
    {{- $superSecret := tpl .Values.insights.postgresql.auth.superUser.existingSecret . -}}
    {{- if contains "credentials.postgresql.acid.zalan.do" $insightsSecret -}}
      {{- fail "insights.postgresql.auth.insightsUser.existingSecret must be overridden to your external secret name when provider=external" -}}
    {{- end -}}
    {{- if contains "credentials.postgresql.acid.zalan.do" $superSecret -}}
      {{- fail "insights.postgresql.auth.superUser.existingSecret must be overridden to your external admin secret name when provider=external" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return host name of the Insights Postgres cluster (operator mode).
DEPRECATED: use cognigy-ai.insights.postgresql.host instead — it handles all provider modes.
Usage:
{{- include "cognigy-ai.insights.postgresql.cluster.host" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.cluster.host" -}}
  {{- include "cognigy-ai.insights.postgresql.host" (dict "context" . "useReadReplica" false) -}}
{{- end -}}
