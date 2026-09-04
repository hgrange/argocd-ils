{{/*
Returns a comma-separated list of namespaces to watch.

The list is built as follows:
1. global.instanceNamespace (falling back to the release namespace) is always included first.
2. When watchNamespace is explicitly set, its entries (split on comma) are appended —
   global.tetheredNamespaces is ignored.
3. When watchNamespace is not set, global.tetheredNamespaces entries are appended instead.
   tetheredNamespaces accepts either a YAML list or a comma-separated string; entries that
   are themselves comma-separated strings are also split correctly.
4. Duplicates are removed before returning.
*/}}
{{- define "ibm-usage-metering.watchNamespaces" -}}
  {{- $instanceNamespace := .Values.global.instanceNamespace | default .Release.Namespace -}}
  {{- $targets := list $instanceNamespace -}}
  {{- $watchNamespace := .Values.ibmUsageMetering.watchNamespace | default "" -}}
  {{- if $watchNamespace -}}
    {{- range $ns := splitList "," $watchNamespace -}}
      {{- $trimmed := trim $ns -}}
      {{- if $trimmed -}}{{- $targets = append $targets $trimmed -}}{{- end -}}
    {{- end -}}
  {{- else -}}
    {{- $tethered := .Values.global.tetheredNamespaces -}}
    {{- $entries := list -}}
    {{- if kindIs "slice" $tethered -}}
      {{- $entries = $tethered -}}
    {{- else -}}
      {{- $entries = list ($tethered | default "") -}}
    {{- end -}}
    {{- range $entry := $entries -}}
      {{- range $ns := splitList "," $entry -}}
        {{- $trimmed := trim $ns -}}
        {{- if $trimmed -}}{{- $targets = append $targets $trimmed -}}{{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $targets | uniq | join "," -}}
{{- end -}}