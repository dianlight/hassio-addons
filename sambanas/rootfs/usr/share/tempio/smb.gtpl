[global]
   min protocol = SMB2
   ea support = yes
   vfs objects = catia fruit streams_xattr  
   fruit:aapl = yes
   fruit:model = MacSamba

   fruit:resource = file
   fruit:veto_appledouble = no
   fruit:posix_rename = yes 
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:zero_file_id = yes
   fruit:delete_empty_adfiles = yes

   netbios name = {{ env "HOSTNAME" }}
   workgroup = {{ .workgroup }}
   server string = Samba NAS HomeAssistant config
   multicast dns register = no

   security = user
   ntlm auth = yes

   load printers = no
   disable spoolss = yes

   log level = 1

   bind interfaces only = yes
   interfaces = {{ .interfaces | join " " }}
   hosts allow = {{ .allow_hosts | join " " }}

   idmap config * : backend = tdb
   idmap config * : range = 3000-7999

   {{ if .compatibility_mode }}
   client min protocol = NT1
   server min protocol = NT1
   {{ end }}

{{ define "SHT" }}
[{{- .share}}]
   browseable = yes
   writeable = yes
   }}
{{ if regexMatch "^(config|addons|ssl|share|backup|media)$" .share }}
   path = /{{- .share}}
{{ else }}
   path = /media/{{- .share}}
{{ end}}   
   valid users = {{ .users|default .username|join " " }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}

   {{- if .timemachine|default false }}
   vfs objects = catia fruit streams_xattr

   # Time Machine Settings Ref: https://github.com/markthomas93/samba.apple.templates
   fruit:time machine = yes
   #fruit:time machine max size = SIZE [K|M|G|T|P]
   fruit:metadata = stream
   {{ end }}
{{ end }}

{{- $disks := concat (list "config" "addons" "ssl" "share" "backup" "media") (compact .moredisks|default list) -}}
{{- $root := . -}}
{{- range $disk := $disks -}}
        {{- $acld := false -}}
        {{- range $dd := $root.acl -}}
                {{- if eq $dd.share $disk -}}
                        {{- $acld = true -}}
                        {{- if not $dd.disabled -}}
                           {{- template "SHT" deepCopy $root |  mergeOverwrite $dd -}}
                        {{- end -}}
                {{- end -}}
        {{- end -}}
        {{- if not $acld -}}
                {{- $dd := dict "share" $disk "timemachine" true -}}
                {{- range $dnt := list "config" "addons" "ssl" "share" "backup" "media" -}}
                        {{- if eq $dnt $disk -}}
                                {{- $_ := set $dd "timemachine" false -}}
                        {{- end -}}
                {{- end -}}
                {{- template "SHT" deepCopy $root | mergeOverwrite $dd -}}
        {{- end -}}
{{- end -}}
