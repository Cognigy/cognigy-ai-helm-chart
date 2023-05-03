{{- define "common.image.render" -}}

{{- $fullName := .image }}

{{- if .global }}
  {{- if .global.imageRegistry }}
    {{- $currentRegistry := .image | toString | regexFind ".*/" | trimSuffix "/" }}
    {{- $fullName = (printf "%s%s" .global.imageRegistry (trimPrefix $currentRegistry .image)) }}
  {{- end }}
{{- end }}

{{- printf "%s" $fullName }}
{{- end }}