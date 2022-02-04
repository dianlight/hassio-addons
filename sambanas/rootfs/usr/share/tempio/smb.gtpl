[global]
   min protocol = SMB2
   ea support = yes
   vfs objects = catia fruit streams_xattr  
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:veto_appledouble = no
   fruit:posix_rename = yes 
   fruit:zero_file_id = yes
   fruit:wipe_intentionally_left_blank_rfork = yes 
   fruit:delete_empty_adfiles = yes

   netbios name = {{ env "HOSTNAME" }}
   workgroup = {{ .workgroup }}
   server string = Samba NAS HomeAssistant config

   security = user
   ntlm auth = yes

   load printers = no
   disable spoolss = yes

   log level = 1

   bind interfaces only = yes
   interfaces = {{ .interface }}
   hosts allow = {{ .allow_hosts | join " " }}

   idmap config * : backend = tdb
   idmap config * : range = 3000-7999

   {{ if .compatibility_mode }}
   client min protocol = NT1
   server min protocol = NT1
   {{ end }}

{{ if .folders.config }}
[config]
   browseable = yes
   writeable = yes
   path = /config

   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}
{{ end }}

{{ if .folders.addons }}
[addons]
   browseable = yes
   writeable = yes
   path = /addons
   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}
{{ end }}

{{ if .folders.ssl }}
[ssl]
   browseable = yes
   writeable = yes
   path = /ssl

   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}
{{ end }}

{{ if .folders.share }}
[share]
   browseable = yes
   writeable = yes
   path = /share
   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}
{{ end }}

{{ if .folders.backup }}
[backup]
   browseable = yes
   writeable = yes
   path = /backup

   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}
{{ end }}

{{ if .folders.media }}
[media]
   browseable = yes
   writeable = yes
   path = /media
   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}
{{ end }}
# MoreDisk Options
