{{/*
Expand the name of the chart.
*/}}
{{- define "helm-chart-cognigy.ai-new.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-chart-cognigy.ai-new.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-chart-cognigy.ai-new.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm-chart-cognigy.ai-new.labels" -}}
helm.sh/chart: {{ include "helm-chart-cognigy.ai-new.chart" . }}
{{ include "helm-chart-cognigy.ai-new.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-chart-cognigy.ai-new.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-chart-cognigy.ai-new.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm-chart-cognigy.ai-new.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm-chart-cognigy.ai-new.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "image.pullSecretsCognigy" -}}
  {{- $pullSecrets := list -}}

  {{- if and (.Values.imageCredentials.registry) (.Values.imageCredentials.username) (.Values.imageCredentials.password) -}}
      {{- $pullSecrets = append $pullSecrets "cognigy-registry-token" -}}
  {{- else if .Values.imageCredentials.pullSecrets -}}
    {{- range .Values.imageCredentials.pullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- else -}}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.registry }}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.username }}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.password }}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.pullSecrets }}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) -}}
imagePullSecrets:
    {{- range $pullSecrets }}
  - name: {{ . }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return the proper smtp password Secret Name
*/}}
{{- define "smtp.password.secretName" -}}
  {{- $smtpPasswordName := "" -}}

  {{- if .Values.smtpPasswordExistingSecret -}}
    {{- $smtpPasswordName = .Values.smtpPasswordExistingSecret -}}
  {{- else -}}
    {{- $smtpPasswordName = "cognigy-smtp" -}}
  {{- end -}}

  {{- printf "%s" (tpl $smtpPasswordName $) -}}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "common.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Return the proper Management Ui Credentials Secret Name
*/}}
{{- define "managementUiCredentials.secretName.render" -}}
  {{- $managementUiCredentialsName := "" -}}

  {{- if .Values.managementUiCredentialsExistingSecret -}}
    {{- $managementUiCredentialsName = .Values.managementUiCredentialsExistingSecret -}}
  {{- else -}}
    {{- $managementUiCredentialsName = "cognigy-management-ui-creds" -}}
  {{- end -}}

  {{- printf "%s" (tpl $managementUiCredentialsName $) -}}
{{- end -}}

{{/*
Return the proper mongodb credentials Secret Name
*/}}
{{- define "mongodbCredentials.secretName.render" -}}
  {{- $mongodbCredentialsSecretName := "" -}}

  {{- if .Values.mongodb.auth.existingSecret -}}
    {{- $mongodbCredentialsSecretName = .Values.mongodb.auth.existingSecret -}}
  {{- else -}}
    {{- $mongodbCredentialsSecretName = "mongodb-connection-creds" -}}
  {{- end -}}

  {{- printf "%s" (tpl $mongodbCredentialsSecretName $) -}}
{{- end -}}

{{/*
Return the proper mongodb Atlas credentials Secret Name
*/}}
{{- define "mongodbAtlasCredentials.secretName.render" -}}
  {{- $mongodbAtlasCredentialsSecretName := "" -}}

  {{- if .Values.mongodb.auth.atlas.existingSecret -}}
    {{- $mongodbAtlasCredentialsSecretName = .Values.mongodb.auth.atlas.existingSecret -}}
  {{- else -}}
    {{- $mongodbAtlasCredentialsSecretName = "mongodb-atlas-creds" -}}
  {{- end -}}

  {{- printf "%s" (tpl $mongodbAtlasCredentialsSecretName $) -}}
{{- end -}}

{{/*
Return the proper tls certificate Secret Name
*/}}
{{- define "tlsCertificate.secretName.render" -}}
  {{- $tlsCertificateSecretName := "" -}}

  {{- if and (.Values.tls.enabled) (.Values.traefik.enabled) -}}
    {{- if .Values.tls.existingSecret -}}
      {{- $tlsCertificateSecretName = .Values.tls.existingSecret -}}
    {{- else if and (.Values.tls.crt) (.Values.tls.key) -}}
      {{- $tlsCertificateSecretName = "cognigy-traefik" -}}
    {{- else -}}
      {{ required "A valid value for .Values.tls is required!" .Values.tls.crt }}
      {{ required "A valid value for .Values.tls is required!" .Values.tls.key }}
      {{ required "A valid value for .Values.tls is required!" .Values.tls.existingSecret }}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $tlsCertificateSecretName)) -}}
tls:
  - secretName: {{- printf "%s" (tpl $tlsCertificateSecretName $) | indent 1 -}}
  {{- end -}}
{{- end -}}

{{/*
Return the proper amazonCredentials Secret Name
*/}}
{{- define "amazonCredentials.secretName.render" -}}
  {{- $amazonCredentialsSecretName := "" -}}

  {{- if .Values.amazonCredentials.existingSecret -}}
    {{- $amazonCredentialsSecretName = .Values.amazonCredentials.existingSecret -}}
  {{- else -}}
    {{- $amazonCredentialsSecretName = "cognigy-amazon-credentials" -}}
  {{- end -}}

  {{- printf "%s" (tpl $amazonCredentialsSecretName $) -}}
{{- end -}}


{{/*
Return the proper cognigyAgentAssist Credentials Secret Name
*/}}
{{- define "agentAssistCredentials.secretName.render" -}}
  {{- $agentAssistCredentialsSecretName := "" -}}

  {{- if .Values.cognigyAgentAssist.existingSecret -}}
    {{- $agentAssistCredentialsSecretName = .Values.cognigyAgentAssist.existingSecret -}}
  {{- else -}}
    {{- $agentAssistCredentialsSecretName = "cognigy-agent-assist-credentials" -}}
  {{- end -}}

  {{- printf "%s" (tpl $agentAssistCredentialsSecretName $) -}}
{{- end -}}

{{/*
Validate values of rabbitmq - Memory high watermark
*/}}
{{- define "rabbitmq.validateValues.memoryHighWatermark" -}}
{{- if and (not (eq .Values.statefulRabbitMq.memoryHighWatermark.type "absolute")) (not (eq .Values.statefulRabbitMq.memoryHighWatermark.type "relative")) }}
rabbitmq: statefulRabbitMq.memoryHighWatermark.type
    Invalid Memory high watermark type. Valid values are "absolute" and
    "relative". Please set a valid mode statefulRabbitMq.memoryHighWatermark.type="xxxx"
{{- else if and .Values.statefulRabbitMq.memoryHighWatermark.enabled (not .Values.statefulRabbitMq.resources.limits.memory) (eq .Values.statefulRabbitMq.memoryHighWatermark.type "relative") }}
rabbitmq: statefulRabbitMq.memoryHighWatermark
    You enabled configuring memory high watermark using a relative limit. However,
    no memory limits were defined at POD level. Define your POD limits as shown below:

    statefulRabbitMq.memoryHighWatermark.enabled=true
    statefulRabbitMq.memoryHighWatermark.type="relative"
    statefulRabbitMq.memoryHighWatermark.value="0.4"
    statefulRabbitMq.resources.limits.memory="2Gi"

    Altenatively, user an absolute value for the memory memory high watermark :

    statefulRabbitMq.memoryHighWatermark.enabled=true
    statefulRabbitMq.memoryHighWatermark.type="absolute"
    statefulRabbitMq.memoryHighWatermark.value="512MB"
{{- end -}}
{{- end -}}

{{/*
Return the number of bytes given a value
following a base 2 or base 10 number system.
Usage:
{{ include "rabbitmq.toBytes" .Values.path.to.the.Value }}
*/}}
{{- define "rabbitmq.toBytes" -}}
{{- $value := int (regexReplaceAll "([0-9]+).*" . "${1}") }}
{{- $unit := regexReplaceAll "[0-9]+(.*)" . "${1}" }}
{{- if eq $unit "Ki" }}
    {{- mul $value 1024 }}
{{- else if eq $unit "Mi" }}
    {{- mul $value 1024 1024 }}
{{- else if eq $unit "Gi" }}
    {{- mul $value 1024 1024 1024 }}
{{- else if eq $unit "Ti" }}
    {{- mul $value 1024 1024 1024 1024 }}
{{- else if eq $unit "Pi" }}
    {{- mul $value 1024 1024 1024 1024 1024 }}
{{- else if eq $unit "Ei" }}
    {{- mul $value 1024 1024 1024 1024 1024 1024 }}
{{- else if eq $unit "K" }}
    {{- mul $value 1000 }}
{{- else if eq $unit "M" }}
    {{- mul $value 1000 1000 }}
{{- else if eq $unit "G" }}
    {{- mul $value 1000 1000 1000 }}
{{- else if eq $unit "T" }}
    {{- mul $value 1000 1000 1000 1000 }}
{{- else if eq $unit "P" }}
    {{- mul $value 1000 1000 1000 1000 1000 }}
{{- else if eq $unit "E" }}
    {{- mul $value 1000 1000 1000 1000 1000 1000 }}
{{- end }}
{{- end -}}


{{/*
Return the proper storageClassName for Flow Modules
Usage:
{{- include "flowModules.storage.class" $ | nindent 2 }}
*/}}
{{- define "flowModules.storage.class" -}}

  {{- $storageClass := "" -}}

  {{- if .Values.flowModules.persistence.storageClass -}}
    {{- $storageClass = .Values.flowModules.persistence.storageClass -}}
  {{- else if eq .Values.cloud.provider "aws" -}}
    {{- $storageClass = "aws-efs-flow-modules" -}}
  {{- else if eq .Values.cloud.provider "azure" -}}
    {{- $storageClass = "flow-modules" -}}
  {{- else if eq .Values.cloud.provider "local-microk8s" -}}
    {{- $storageClass = "microk8s-hostpath" -}}
  {{- else if eq .Values.cloud.provider "local-rancher" -}}
    {{- $storageClass = "local-path" -}}
  {{- end -}}

  {{- if (not (empty $storageClass)) -}}
    {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}


{{/*
Return the proper storageClassName for Functions
Usage:
{{- include "functions.storage.class" $ | nindent 2 }}
*/}}
{{- define "functions.storage.class" -}}

  {{- $storageClass := "" -}}

  {{- if .Values.functions.persistence.storageClass -}}
    {{- $storageClass = .Values.functions.persistence.storageClass -}}
  {{- else if eq .Values.cloud.provider "aws" -}}
    {{- $storageClass = "aws-efs-functions" -}}
  {{- else if eq .Values.cloud.provider "azure" -}}
    {{- $storageClass = "functions" -}}
  {{- else if eq .Values.cloud.provider "local-microk8s" -}}
    {{- $storageClass = "microk8s-hostpath" -}}
  {{- else if eq .Values.cloud.provider "local-rancher" -}}
    {{- $storageClass = "local-path" -}}
  {{- end -}}

  {{- if (not (empty $storageClass)) -}}
    {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}


{{/*
Return the proper storageClassName for Flow Modules in legacy system with annotation
Usage:
{{- include "flowModules.legacy.storage.class" $ | nindent 2 }}
*/}}
{{- define "flowModules.legacy.storage.class" -}}

  {{- $storageClass := "" -}}

  {{- if .Values.flowModules.persistence.storageClass -}}
    {{- $storageClass = .Values.flowModules.persistence.storageClass -}}
  {{- else if eq .Values.cloud.provider "aws" -}}
    {{- $storageClass = "aws-efs-flow-modules" -}}
  {{- else if eq .Values.cloud.provider "azure" -}}
    {{- $storageClass = "flow-modules" -}}
  {{- else if eq .Values.cloud.provider "local-microk8s" -}}
    {{- $storageClass = "microk8s-hostpath" -}}
  {{- else if eq .Values.cloud.provider "local-rancher" -}}
    {{- $storageClass = "local-path" -}}
  {{- end -}}

  {{- if (not (empty $storageClass)) -}}
    {{- printf "volume.beta.kubernetes.io/storage-class: \"%s\"" $storageClass -}}
  {{- end -}}
{{- end -}}


{{/*
Return the proper storageClassName for Functions in legacy system with annotation
Usage:
{{- include "functions.legacy.storage.class" $ | nindent 2 }}
*/}}
{{- define "functions.legacy.storage.class" -}}

  {{- $storageClass := "" -}}

  {{- if .Values.functions.persistence.storageClass -}}
    {{- $storageClass = .Values.functions.persistence.storageClass -}}
  {{- else if eq .Values.cloud.provider "aws" -}}
    {{- $storageClass = "aws-efs-functions" -}}
  {{- else if eq .Values.cloud.provider "azure" -}}
    {{- $storageClass = "functions" -}}
  {{- else if eq .Values.cloud.provider "local-microk8s" -}}
    {{- $storageClass = "microk8s-hostpath" -}}
  {{- else if eq .Values.cloud.provider "local-rancher" -}}
    {{- $storageClass = "local-path" -}}
  {{- end -}}

  {{- if (not (empty $storageClass)) -}}
    {{- printf "volume.beta.kubernetes.io/storage-class: \"%s\"" $storageClass -}}
  {{- end -}}
{{- end -}}


{{/*
Return the proper EFS ID for Flow Modules
Usage:
{{- include "flowModules.efs.id" $ | indent 1 }}
*/}}
{{- define "flowModules.efs.id" -}}
  {{- if and (eq .Values.cloud.provider "aws") (.Values.flowModules.persistence.aws.efs.enabled) -}}

    {{- $efsID := "" -}}
    {{- if .Values.flowModules.persistence.aws.efs.id -}}
      {{- $efsID = .Values.flowModules.persistence.aws.efs.id -}}
    {{- else if .Values.efs.flowModules.id -}}
      {{- $efsID = .Values.efs.flowModules.id -}}
    {{- else -}}
        {{ required "A valid value for .Values.flowModules.persistence.aws.efs.id is required!" .Values.flowModules.persistence.aws.efs.id }}
        {{ required "A valid value for .Values.efs.flowModules.id is required!" .Values.efs.flowModules.id }}
    {{- end -}}

    {{- if (not (empty $efsID)) -}}
      {{- printf "%s" (tpl $efsID $) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{/*
Return the proper EFS ID for Functions
Usage:
{{- include "functions.efs.id" $ | indent 1 }}
*/}}
{{- define "functions.efs.id" -}}
  {{- if and (eq .Values.cloud.provider "aws") (.Values.functions.persistence.aws.efs.enabled) -}}

    {{- $efsID := "" -}}
    {{- if .Values.functions.persistence.aws.efs.id -}}
      {{- $efsID = .Values.functions.persistence.aws.efs.id -}}
    {{- else if .Values.efs.functions.id -}}
      {{- $efsID = .Values.efs.functions.id -}}
    {{- else -}}
        {{ required "A valid value for .Values.functions.persistence.aws.efs.id is required!" .Values.functions.persistence.aws.efs.id }}
        {{ required "A valid value for .Values.efs.functions.id is required!" .Values.efs.functions.id }}
    {{- end -}}

    {{- if (not (empty $efsID)) -}}
      {{- printf "%s" (tpl $efsID $) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Renders a secret name. Prints existingSecret name if existingSecret is defined, else prints default secret name.
Usage:
{{ include "common.secretName.render" ( dict "existingSecret" .Values.path.to.the.existing.secret "defaultSecret" .Values.path.to.the.default.secret) }}
*/}}
{{- define "common.secretName.render" -}}
  {{- $secretName := "" -}}

  {{- if .existingSecret -}}
    {{- $secretName = .existingSecret -}}
  {{- else -}}
    {{- $secretName = .defaultSecret -}}
  {{- end -}}

  {{- printf $secretName -}}
{{- end -}}

{{/*
  Create a list of cube-store-worker pods based on replica count
*/}}
{{- define "cubejs.cubeStoreWorkers" -}}
  {{- $workers := list }}
   {{- $workerPort := .Values.cubejs.storeWorker.workerPort | int }}
  {{- range $i, $e := until (int .Values.cubejs.storeWorker.replicaCount) }}
    {{- $workers = append $workers (printf "cube-store-worker-%d.cube-store-worker:%d" $i $workerPort) }}
  {{- end }}

  {{- printf "%s" (join "," $workers | quote) }}
{{- end }}

{{/*
Return name of the secret with the password for CubeJS Postgres database
Usage:
{{- include "cubejs.postgresql.password.existingSecret" $ }}
*/}}
{{- define "cubejs.postgresql.password.existingSecret" -}}
  {{- $passwordSecret := "" -}}

  {{- if and (.Values.cubejs.postgresql.cluster ) (.Values.cubejs.postgresql.username) }}
    {{- $passwordSecret = printf "%s.%s.credentials.postgresql.acid.zalan.do" $.Values.cubejs.postgresql.username $.Values.cubejs.postgresql.cluster | quote  }}
  {{- else -}}
      {{ required "A valid value for .Values.cubejs.postgresql.cluster is required!" .Values.cubejs.postgresql.cluster }}
      {{ required "A valid value for .Values.cubejs.postgresql.username is required!" .Values.cubejs.postgresql.username }}
  {{- end -}}

  {{- printf $passwordSecret -}}
{{- end -}}

{{/*
Return the number of bytes given a value
following a base 2 or base 10 number system.
Input can be: b | B | k | K | m | M | g | G | Ki | Mi | Gi
Or number without suffix
Usage:
{{ include "cognigy-ai.toBytes" .Values.path.to.the.Value }}
*/}}
{{- define "cognigy-ai.toBytes" -}}
    {{- $si := . -}}
    {{- if not (typeIs "string" . ) -}}
        {{- $si = int64 $si | toString -}}
    {{- end -}}
    {{- $bytes := 0 -}}
    {{- if or (hasSuffix "B" $si) (hasSuffix "b" $si) -}}
        {{- $bytes = $si | trimSuffix "B" | trimSuffix "b" | float64 | floor -}}
    {{- else if or (hasSuffix "K" $si) (hasSuffix "k" $si) -}}
        {{- $raw := $si | trimSuffix "K" | trimSuffix "k" | float64 -}}
        {{- $bytes = mulf $raw (mul 1000) | floor -}}
    {{- else if or (hasSuffix "M" $si) (hasSuffix "m" $si) -}}
        {{- $raw := $si | trimSuffix "M" | trimSuffix "m" | float64 -}}
        {{- $bytes = mulf $raw (mul 1000 1000) | floor -}}
    {{- else if or (hasSuffix "G" $si) (hasSuffix "g" $si) -}}
        {{- $raw := $si | trimSuffix "G" | trimSuffix "g" | float64 -}}
        {{- $bytes = mulf $raw (mul 1000 1000 1000) | floor -}}
    {{- else if hasSuffix "Ki" $si -}}
        {{- $raw := $si | trimSuffix "Ki" | float64 -}}
        {{- $bytes = mulf $raw (mul 1024) | floor -}}
    {{- else if hasSuffix "Mi" $si -}}
        {{- $raw := $si | trimSuffix "Mi" | float64 -}}
        {{- $bytes = mulf $raw (mul 1024 1024) | floor -}}
    {{- else if hasSuffix "Gi" $si -}}
        {{- $raw := $si | trimSuffix "Gi" | float64 -}}
        {{- $bytes = mulf $raw (mul 1024 1024 1024) | floor -}}
    {{- else if (mustRegexMatch "^[0-9]+$" $si) -}}
        {{- $bytes = $si -}}
    {{- else -}}
        {{- printf "\n%s is invalid SI quantity\nSuffixes can be: b | B | k | K | m | M | g | G | Ki | Mi | Gi or without any Suffixes" $si | fail -}}
    {{- end -}}
    {{- $bytes | int64 -}}
{{- end -}}

