{{/*
Render the Triton Inference Server args that enable OpenTelemetry tracing for the
service-nlp-embedding-* deployments, from the same tracing.openTelemetry values that
cognigy-common.telemetry.otel.env reads for the other services.

Triton is not configured through OTEL_* env vars but through --trace-config flags:
- level=TIMESTAMPS: Triton's trace level defaults to DISABLED.
- rate=0: only requests that carry a propagated W3C traceparent are traced (Triton's
  default rate would also start a root trace for every 1000th untraced request).
- opentelemetry,url: Triton takes the full OTLP/HTTP traces URL, not the base endpoint.

The args are only rendered when tracing.openTelemetry.triton.enabled is true (default
false: with tracing on, Triton 24.10 segfaulted under load and hung until the liveness
probe killed it), and when Triton can follow the shared settings:
- Triton exports OTLP over HTTP only, so a grpc protocol leaves it untraced.
- Triton traces every request with a valid propagated context and ignores its sampled
  flag; it has no sampler setting of its own. With a sampler that drops some traces
  (e.g. parentbased_traceidratio) it would export spans whose parents were never
  exported, so it is only traced when every trace is sampled.

Usage (inside the container's args list; `with` keeps the render unchanged when it is empty):
{{- with include "cognigy-ai.tracing.otel.tritonArgs" (dict "context" $ "serviceName" "service-nlp-embedding-en") }}
{{- . | nindent 12 }}
{{- end }}
*/}}
{{- define "cognigy-ai.tracing.otel.tritonArgs" -}}
{{- $ctx := .context -}}
{{- $otel := ($ctx.Values.tracing | default dict).openTelemetry | default dict -}}
{{- $samplesAll := has ($otel.sampler | default "parentbased_always_on" | toString) (list "parentbased_always_on" "always_on") -}}
{{- $overHttp := ne ($otel.protocol | default "" | toString) "grpc" -}}
{{- $tritonEnabled := ($otel.triton | default dict).enabled -}}
{{- if and $otel.enabled $tritonEnabled $samplesAll $overHttp }}
{{- $endpoint := required "tracing.openTelemetry.endpoint is required when tracing.openTelemetry.enabled is true" $otel.endpoint -}}
{{- $url := printf "%s/v1/traces" (include "cognigy-common.tplvalues.render" (dict "value" $endpoint "context" $ctx) | trimSuffix "/") -}}
{{- $args := list
  "--trace-config=mode=opentelemetry"
  "--trace-config=level=TIMESTAMPS"
  "--trace-config=rate=0"
  (printf "--trace-config=opentelemetry,url=%s" $url)
  (printf "--trace-config=opentelemetry,resource=service.name=%s" .serviceName)
  (printf "--trace-config=opentelemetry,resource=service.version=%s" $ctx.Chart.AppVersion)
-}}
{{- toYaml $args }}
{{- end }}
{{- end -}}
