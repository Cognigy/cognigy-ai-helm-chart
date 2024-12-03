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
