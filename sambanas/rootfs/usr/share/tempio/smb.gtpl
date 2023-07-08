[global]
   {{ if .compatibility_mode }}
   client min protocol = NT1
   server min protocol = NT1
   {{ else }}
   server min protocol = SMB2_10
   client min protocol = SMB2_10
   {{ end }}


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

   {{ $log_level := dict "trace" "5" "debug" "4" "info" "3" "notice" "2" "warning" "1" "error" "1"  "fatal" "1" -}}
   log level = {{ .log_level | default "warning" | get $log_level }}

   bind interfaces only = yes
   interfaces = {{ .interfaces | join " " }} {{ .docker_interface | default " "}}
   hosts allow = {{ .allow_hosts | join " " }} {{ .docker_net | default " " }}

   idmap config * : backend = tdb
   idmap config * : range = 3000-7999


   mangled names = no
   dos charset = CP850
   unix charset = UTF-8   

{{ define "SHT" }}
[{{- regexReplaceAll "[^A-Za-z0-9_/ ]" .share "_" | regexFind "[A-Za-z0-9_ ]+$"}}]
   browseable = yes
   writeable = yes

   path = /{{- .share }}
   valid users = {{ .users|default .username|join " " }} {{ .ro_users|join " " }}
   {{ if .ro_users }}
   read list = {{ .ro_users|join " " }}
   {{ end }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}

# TM:{{ .timemachine }} {{- if .medialibrary.enable }} USAGE:{{ .usage | default "" }} {{ end }}
   {{- if .timemachine }}
   vfs objects = catia fruit streams_xattr

   # Time Machine Settings Ref: https://github.com/markthomas93/samba.apple.templates
   fruit:time machine = yes
   #fruit:time machine max size = SIZE [K|M|G|T|P]
   fruit:metadata = stream
   {{ end }}
{{ end }}

{{- $dfdisk := list "config" "addons" "ssl" "share" "backup" "media" }}
{{- $disks := concat $dfdisk (compact .moredisks|default list) -}}
{{- $root := . -}}
{{- range $disk := $disks -}}
        {{- $acld := false -}}
        {{- range $dd := $root.acl -}}
                {{- $ndisk := $disk | regexFind "[A-Za-z0-9_]+$" -}} 
                {{- if eq $dd.share $ndisk -}}
                        {{- $def := deepCopy $dd }}
                        {{- $acld = true -}}
                        {{- if not $dd.disabled -}}
                           {{- $_ := set $dd "share" $disk -}}
                           {{- if has $disk $dfdisk -}}
                                {{- $_ := set $def "timemachine" false -}}
                                {{- $_ := set $def "usage" "" -}}
                           {{- else -}}
                                {{- $_ := set $def "timemachine" true -}}
                                {{- $_ := set $def "usage" "media" -}}
                           {{- end }}
                           {{- template "SHT" deepCopy $root | mergeOverwrite $def $dd -}}
                        {{- end -}}
                {{- end -}}
        {{- end -}}
        {{- if not $acld -}}
                {{- $dd := dict "share" $disk "timemachine" true -}}
                {{- $_ := set $dd "usage" "media" -}}
                {{- if has $disk $dfdisk -}}
                        {{- $_ := set $dd "timemachine" false -}}
                        {{- $_ := set $dd "usage" "" -}}
                {{- end }}
                {{- template "SHT" (deepCopy $root | mergeOverwrite $dd) -}}
        {{- end -}}
{{- end -}}
