{{/*
Render the OpenTelemetry env vars shared by every Cognigy service.

Emits nothing when tracing.openTelemetry.enabled is false, so a chart with tracing
off renders byte-identically to before this helper existed.

An enabled section with an empty endpoint is a misconfiguration, not a no-op: the
services' bootstrap (shared/observability/otel.ts) silently skips tracing without
OTEL_EXPORTER_OTLP_ENDPOINT, so `required` fails the render here instead of shipping
pods that look traced but are not.

OTEL_SERVICE_NAME is intentionally never set here — each service passes its own name
to initOtel(), and a chart-level value would be the same string for every service and
would override all of them.

OTEL_RESOURCE_ATTRIBUTES is intentionally never set here — see the comment on
tracing.openTelemetry.extraEnvVars in values.yaml for why.

Usage:
{{- include "cognigy-ai.tracing.otel.render" (dict "context" $) | nindent 12 }}
*/}}
{{- define "cognigy-ai.tracing.otel.render" -}}
{{- $ctx := index . "context" -}}
{{- $otel := $ctx.Values.tracing.openTelemetry -}}
{{- if $otel.enabled }}
{{- $envVars := list -}}
{{- $endpoint := required "tracing.openTelemetry.endpoint is required when tracing.openTelemetry.enabled is true" $otel.endpoint -}}
{{- $envVars = append $envVars (dict "name" "OTEL_EXPORTER_OTLP_ENDPOINT" "value" (include "common.tplvalues.render" (dict "value" $endpoint "context" $ctx))) -}}
{{- if $otel.sampler }}
{{- $envVars = append $envVars (dict "name" "OTEL_TRACES_SAMPLER" "value" ($otel.sampler | toString)) -}}
{{- end }}
{{- if $otel.samplerArg }}
{{- $envVars = append $envVars (dict "name" "OTEL_TRACES_SAMPLER_ARG" "value" ($otel.samplerArg | toString)) -}}
{{- end }}
{{- if $otel.enabledInstrumentations }}
{{- $envVars = append $envVars (dict "name" "OTEL_NODE_ENABLED_INSTRUMENTATIONS" "value" ($otel.enabledInstrumentations | toString)) -}}
{{- end }}
{{- if $otel.debugConsoleSpans }}
{{- $envVars = append $envVars (dict "name" "OTEL_DEBUG_CONSOLE_SPANS" "value" "true") -}}
{{- end }}
{{- toYaml $envVars }}
{{- if $otel.extraEnvVars }}
{{- include "common.tplvalues.render" (dict "value" $otel.extraEnvVars "context" $ctx) }}
{{- end }}
{{- end }}
{{- end -}}
