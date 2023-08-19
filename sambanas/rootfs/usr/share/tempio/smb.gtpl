# This is the main Samba configuration file. You should read the
# smb.conf(5) manual page in order to understand the options listed
# here. Samba has a huge number of configurable options (perhaps too
# many!) most of which are not shown in this example
#
# For a step to step guide on installing, configuring and using samba, 
# read the Samba-HOWTO-Collection. This may be obtained from:
#  http://www.samba.org/samba/docs/Samba-HOWTO-Collection.pdf
#
# Many working examples of smb.conf files can be found in the 
# Samba-Guide which is generated daily and can be downloaded from: 
#  http://www.samba.org/samba/docs/Samba-Guide.pdf
#
# Any line which starts with a ; (semi-colon) or a # (hash) 
# is a comment and is ignored. In this example we will use a #
# for commentry and a ; for parts of the config file that you
# may wish to enable
#
# NOTE: Whenever you modify this file you should run the command "testparm"
# to check that you have not made any basic syntactic errors. 
#
#======================= Global Settings =====================================
[global]
# workgroup = NT-Domain-Name or Workgroup-Name, eg: MIDEARTH
   workgroup = {{ .workgroup }}

# server string is the equivalent of the NT Description field
   server string = Samba NAS HomeAssistant config

# Server role. Defines in which mode Samba will operate. Possible
# values are "standalone server", "member server", "classic primary
# domain controller", "classic backup domain controller", "active
# directory domain controller".
#
# Most people will want "standalone sever" or "member server".
# Running as "active directory domain controller" will require first
# running "samba-tool domain provision" to wipe databases and create a
# new domain.
   server role = standalone server

# This option is important for security. It allows you to restrict
# connections to machines which are on your local network. The
# following example restricts access to two C class networks and
# the "loopback" interface. For more examples of the syntax see
# the smb.conf man page
   hosts allow = {{ .allow_hosts | join " " }} {{ .docker_net | default " " }}

# Uncomment this if you want a guest account, you must add this to /etc/passwd
# otherwise the user "nobody" is used
#  guest account = pcguest

# this tells Samba to use a separate log file for each machine
# that connects
   log file = /usr/local/samba/var/log.%m

# Put a capping on the size of the log files (in Kb).
   max log size = 50

# Specifies the Kerberos or Active Directory realm the host is part of
#   realm = MY_REALM

# Backend to store user information in. New installations should 
# use either tdbsam or ldapsam. smbpasswd is available for backwards 
# compatibility. tdbsam requires no further configuration.
#   passdb backend = tdbsam

# Using the following line enables you to customise your configuration
# on a per machine basis. The %m gets replaced with the netbios name
# of the machine that is connecting.
# Note: Consider carefully the location in the configuration file of
#       this line.  The included file is read at that point.
#   include = /usr/local/samba/lib/smb.conf.%m

# Configure Samba to use multiple interfaces
# If you have multiple network interfaces then you must list them
# here. See the man page for details.
   interfaces = {{ .interfaces | join " " }} {{ .docker_interface | default " "}}

# Configure Samba to use only interfaces defined in interfaces.
# See the man page for details.
   bind interfaces only = yes

# Where to store roving profiles (only for Win95 and WinNT)
#        %L substitutes for this servers netbios name, %U is username
#        You must uncomment the [Profiles] share below
#   logon path = \\%L\Profiles\%U

# Windows Internet Name Serving Support Section:
# WINS Support - Tells the NMBD component of Samba to enable it's WINS Server
#   wins support = yes

# WINS Server - Tells the NMBD components of Samba to be a WINS Client
#	Note: Samba can be either a WINS Server, or a WINS Client, but NOT both
#   wins server = w.x.y.z

# WINS Proxy - Tells Samba to answer name resolution queries on
# behalf of a non WINS capable client, for this to work there must be
# at least one	WINS Server on the network. The default is NO.
#   wins proxy = yes

# DNS Proxy - tells Samba whether or not to try to resolve NetBIOS names
# via DNS nslookups. The default is NO.
   dns proxy = yes 

# These scripts are used on a domain controller or stand-alone 
# machine to add or delete corresponding unix accounts
#  add user script = /usr/sbin/useradd %u
#  add group script = /usr/sbin/groupadd %g
#  add machine script = /usr/sbin/adduser -n -g machines -c Machine -d /dev/null -s /bin/false %u
#  delete user script = /usr/sbin/userdel %u
#  delete user from group script = /usr/sbin/deluser %u %g
#  delete group script = /usr/sbin/groupdel %g

# This sets the NetBIOS name by which a Samba server is known.
# By default it is the same as the first component of the host's DNS name.
#
# Note that the maximum length for a NetBIOS name is 15 characters.
   netbios name = {{ env "HOSTNAME" }}

# Samba will announce itself with multicast DNS services.
   multicast dns register = yes

# Settings for the minimum protocol.
   {{ if .compatibility_mode }}
   client min protocol = NT1
   server min protocol = NT1
   {{ else }}
   server min protocol = SMB2_10
   client min protocol = SMB2_10
   {{ end }}

# Allow clients to attempt to access extended attributes on a share.
   ea support = yes

# Backend names which are used for Samba VFS I/O operation
# catia - Translates illegal characters in file names used by the Catia application.
# fruit - Provides enhanced compatibility with Apple Server Message Block (SMB) clients and interoperability with Netatalk 3 Apple Filing Protocol (AFP) file servers.
# streams_xattr - Enables ADS support.
# recycle - Moves files to a temporary directory rather than deleting them immediately.
   vfs objects = catia fruit streams_xattr{{ if .recyle_bin_enabled }} recycle{{ end }}

# fruit parameters for MAC OS compatability
   fruit:aapl = yes
   fruit:model = MacSamba
   fruit:resource = file
   fruit:veto_appledouble = no
   fruit:posix_rename = yes 
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:zero_file_id = yes
   fruit:delete_empty_adfiles = yes
   fruit:encoding = private
   fruit:locking = none
   fruit:copyfile = yes
   fruit:nfs_aces = no

# Security paramters for authetication
   security = user
   ntlm auth = yes

# Disabling printer sharing
   load printers = no
   disable spoolss = yes

# Log levels
   {{ $log_level := dict "trace" "5" "debug" "4" "info" "3" "notice" "2" "warning" "1" "error" "1"  "fatal" "1" -}}
   log level = {{ .log_level | default "warning" | get $log_level }}
   logging = syslog

   idmap config * : backend = tdb
   idmap config * : range = 3000-7999

   mangled names = no
   dos charset = CP850
   unix charset = UTF-8   
   store dos attributes = yes

# Performance Enhancements for network
   socket options = TCP_NODELAY IPTOS_LOWDELAY
   min receivefile size = 16384
   getwd cache = yes
   aio read size = 1
   aio write size = 1  

#=========================== Allow {{ .admin_username }} root access ===========================
   admin users = {{ .admin_username }}

#======================= Share Definitions =======================
{{ define "SHT" }}
[{{- regexReplaceAll "[^A-Za-z0-9_/ ]" .share "_" | regexFind "[A-Za-z0-9_ ]+$"}}]
   browseable = yes
   writeable = yes
   follow symlinks = yes
   hide dot files = no
   create mask = 0664
   force create mode = 0664
   directory mask = 0775
   force directory mode = 0775

   path = /{{- .share }}
   valid users = {{ .users|default .username|join " " }} {{ .ro_users|join " " }}
   {{ if .ro_users }}
   read list = {{ .ro_users|join " " }}
   {{ end }}
   force user = root
   force group = root
   veto files = /{{ .veto_files | join "/" }}/
   delete veto files = {{ eq (len .veto_files) 0 | ternary "no" "yes" }}

# RECYCLE:{{if .recyle_bin_enabled }}
   recycle:repository = .recycle/%U
   recycle:keeptree = yes
   recycle:versions = yes
   recycle:touch = yes
   recycle:touch_mtime = no
   recycle:directory_mode = 0777
   recycle:subdir_mode = 0700
   recycle:exclude =
   recycle:exclude_dir =
   recycle:maxsize = 0{{ end }}

# TM:{{ .timemachine }} {{- if .medialibrary.enable }} USAGE:{{ .usage | default "" }} {{ end }}
   {{- if .timemachine }}
   vfs objects = catia fruit streams_xattr{{ if .recyle_bin_enabled }} recycle{{ end }}

   # Time Machine Settings Ref: https://github.com/markthomas93/samba.apple.templates
   fruit:time machine = yes
   #fruit:time machine max size = SIZE [K|M|G|T|P]
   fruit:metadata = stream
   fruit:encoding = private
   fruit:locking = none
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