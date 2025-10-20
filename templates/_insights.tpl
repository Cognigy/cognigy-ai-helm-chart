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
Return host name of the Insights Postgres database
Usage:
{{- include "cognigy-ai.insights.postgresql.cluster.host" $ }}
*/}}
{{- define "cognigy-ai.insights.postgresql.cluster.host" -}}
  {{- $postgresqlHost := "" -}}

  {{- if .Values.insights.postgresql.cluster.readReplica.useReadReplica -}}
    {{- $postgresqlHost = .Values.insights.postgresql.cluster.readReplica.host -}}
  {{- else -}}
    {{- $postgresqlHost = .Values.insights.postgresql.cluster.host -}}
  {{- end -}}

  {{- printf "%s" (include "common.tplvalues.render" (dict "value" $postgresqlHost "context" $)) -}}
{{- end -}}
