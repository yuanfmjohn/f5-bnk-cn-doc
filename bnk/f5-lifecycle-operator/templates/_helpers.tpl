{{/* vim: set filetype=mustache: */}}

{{- define "f5-lifecycle-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "f5-lifecycle-operator.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "f5-lifecycle-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount -}}
    {{- if .Values.serviceAccount.create -}}
        {{ default (include "f5-lifecycle-operator.fullname" .) .Values.serviceAccount.name }}
    {{- else -}}
        {{ default "default-flo-sa" .Values.serviceAccount.name }}
    {{- end -}}
{{- else -}}
    {{ default "default-flo-sa" }}
{{- end -}}
{{- end -}}

{{- define "f5-lifecycle-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "f5-lifecycle-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "f5-lifecycle-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "f5-lifecycle-operator.labels" -}}
helm.sh/chart: {{ include "f5-lifecycle-operator.chart" . }}
{{ include "f5-lifecycle-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "f5-lifecycle-operator.namespace" -}}
    {{ .Values.namespace | default .Release.Namespace }}
{{- end -}}

{{- define "f5-lifecycle-operator.image" -}}
{{- $defaultTag := index . 1 -}}
{{- $defaultRepository := index . 2 -}}
{{- with index . 0 -}}
{{- printf "%s/%s:%s" (default $defaultRepository .repository) .name (default $defaultTag .tag) }}
{{- end }}
{{- end }}
