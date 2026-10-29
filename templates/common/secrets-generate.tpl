{{- define "connectionString.mongodb" -}}
{{- $dbName := default .serviceName .dbName -}}
{{- .mongodbScheme }}://{{- .serviceName -}}:{{- .pw -}}@{{- .mongodbHosts -}}/{{- $dbName -}}{{- .mongodbParams }}
{{- end }}

{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}
