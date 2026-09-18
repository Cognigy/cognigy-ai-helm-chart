{{- define "service-task-manager.runKnowledgeExtensionJobTemplate" -}}
{{- $statefulRabbitMq_secret := include "common.secretName.render" ( dict "existingSecret" $.Values.statefulRabbitMq.auth.existingSecret "defaultSecret" "cognigy-rabbitmq") }}
{{- $redisHa_secret := include "common.secretName.render" ( dict "existingSecret" $.Values.redisHa.auth.existingSecret "defaultSecret" "cognigy-redis-password") }}
{{- with .Values.taskRunKnowledgeExtension }}
spec:
  backoffLimit: {{ .backoffLimit | default 0 }}
  activeDeadlineSeconds: {{ .activeDeadlineSeconds }}
  ttlSecondsAfterFinished: {{ .ttlSecondsAfterFinished }}
  template:
    spec:
      securityContext:
        {{- toYaml .securityContext | nindent 8 }}
      restartPolicy: {{ .restartPolicy | default "Never" }}
      {{- if .affinity }}
      affinity: {{- include "common.tplvalues.render" (dict "value" .affinity "context" $) | nindent 8 }}
      {{- end }}
      {{- if .nodeSelector }}
      nodeSelector: {{- include "common.tplvalues.render" (dict "value" .nodeSelector "context" $) | nindent 8 }}
      {{- end }}
      {{- if .tolerations }}
      tolerations: {{- include "common.tplvalues.render" (dict "value" .tolerations "context" $) | nindent 8 }}
      {{- end }}
      {{- if .priorityClassName }}
      priorityClassName: {{ .priorityClassName }}
      {{- end }}
      containers:
        - name: task-run-knowledge-extension
          image: {{ include "common.image.render" (dict "global" $.Values.global "image" .image) }}
          resources: {{- toYaml .resources | nindent 12 }}
          envFrom:
            - configMapRef:
                name: cognigy-env
          env:
            - name: JOB_ARGUMENTS
              value: "_JOB_ARGUMENTS_"
            - name: TRACING_ENABLED
              value: {{ $.Values.tracing.sentry.ide.enabled | quote }}
            - name: TRACING_BASE_URL_WITH_PROTOCOL
              value: {{ $.Values.tracing.sentry.ide.baseUrl | quote }}
            - name: TRACING_ERRORS_ENABLED
              value: {{ $.Values.tracing.sentry.ide.errorsEnabled | quote }}
            - name: TRACING_EVENTS_SAMPLE_RATE
              value: {{ $.Values.tracing.sentry.ide.eventsSampleRate | quote }}
            - name: TRACING_SAMPLE_RATE
              value: {{ $.Values.tracing.sentry.ide.sampleRate | quote }}
            - name: ENVIRONMENT
              value: {{ $.Values.tracing.environment | quote }}
            - name: COGNIGY_AI_RELEASE_VERSION
              value: {{ $.Chart.AppVersion | quote }}
            {{- if .extraEnvVars }}
            {{- include "common.tplvalues.render" (dict "value" .extraEnvVars "context" $) | nindent 12 }}
            {{- end }}
          volumeMounts:
            - name: rabbitmq-connection-string
              mountPath: /var/run/secrets/rabbitmqConnectionString
              subPath: rabbitmqConnectionString
            - name: redis-password
              mountPath: /var/run/secrets/redis-password.conf
              subPath: redis-password.conf
            {{- if $.Values.migrateFS.enabled }}
            - name: runtime
              mountPath: /app/node_modules/_EXTENSION_ID_
              subPath: _EXTENSION_PATH_
            {{- else }}
            - name: flow-modules
              mountPath: /app/node_modules/_EXTENSION_ID_
              subPath: _EXTENSION_PATH_
            {{- end }}
            {{- if .extraVolumeMounts }}
            {{- include "common.tplvalues.render" ( dict "value" .extraVolumeMounts "context" $ ) | nindent 12 }}
            {{- end }}
      volumes:
        - name: rabbitmq-connection-string
          secret:
            secretName: {{ $statefulRabbitMq_secret }}
            items:
              - key: connection-string
                path: rabbitmqConnectionString
        - name: redis-password
          secret:
            secretName: {{ $redisHa_secret }}
        {{- if $.Values.migrateFS.enabled }}
        - name: runtime
          persistentVolumeClaim:
            claimName: runtime
        {{- else }}
        - name: flow-modules
          persistentVolumeClaim:
            claimName: flow-modules
        {{- end }}
        {{- if .extraVolumes }}
        {{- include "common.tplvalues.render" ( dict "value" .extraVolumes "context" $ ) | nindent 8 }}
        {{- end }}
      {{- include "image.pullSecretsCognigy" $ | nindent 6 }}
{{- end }}
{{- end -}}