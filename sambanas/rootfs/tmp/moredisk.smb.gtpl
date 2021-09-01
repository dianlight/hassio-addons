[%%DISKNAME%%]
   browseable = yes
   writeable = yes
   path = /%%DISKNAME%%

   valid users = {{ .username }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}  

   vfs objects = catia fruit streams_xattr
   fruit:aapl = yes
   fruit:time machine = yes