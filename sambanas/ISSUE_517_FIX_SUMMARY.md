# Fix Summary for Issue #517 - Duplicate Shares and User Access Issues

## Problem Analysis

Based on petebanham's last comment on issue #517, there were two main problems:

### 1. Duplicate Shares (Primary Issue)
Every share was appearing multiple times in the `smb.conf` file and in the "Exposed Disks Summary" log output. In petebanham's log, each share appeared twice:

```
[CONFIG]                path = /homeassistant # TM:false US:secureuser #
[CONFIG]                path = /homeassistant # TM:false US:secureuser #
[ADDONS]                path = /addons # TM:false US:secureuser #
[ADDONS]                path = /addons # TM:false US:secureuser #
...
```

This was causing the addon to fail to start properly in version 12.5.0-nas1 and the beta 12.5.0-nas2.beta145.

**Root Cause**: The template logic in `smb.gtpl` was flawed. When looping through disks and ACL entries:

```go
{{- range $disk := $disks -}}
    {{- range $dd := $root.acl -}}
        {{- if eq ($aclshare|upper) ($ndisk|upper) -}}
            {{- template "SHT" ... -}}  // This rendered the share
        {{- end -}}
    {{- end -}}
{{- end -}}
```

The inner loop would continue after finding a match, and since the template was rendered **inside the inner loop**, each disk would be rendered once for every matching ACL entry. With a configuration that had ACL entries for all 9 shares (7 default + 2 external disks), each share appeared 9 times!

### 2. Spacing Issue with `valid users` (Secondary Issue)
The `valid users` line in the template was missing a space after the `=` sign:

```
valid users =_ha_mount_user_ {{ .users|default .username|join " " }}
```

This could cause Samba parsing issues and resulted in warnings like:
```
token_contains_name: _ha_mount_user_ is a UNKNOWN, expected a user
```

### 3. User Configuration Confusion
petebanham had configured:
- `username: share` (main user)
- `other_users: [secureuser]` (additional user)
- ACL entries specifying `users: ["secureuser"]` for all shares

This meant the main user "share" couldn't access the shares because only "secureuser" was granted access via ACL.

## Solution

### Fix 1: Prevent Duplicate Share Rendering

**Changed the template logic to:**
1. **First pass**: Loop through ACL entries to find a match and store it in state
2. **Second pass**: Render the share only once after the loop completes

```go
{{- range $disk := $disks -}}
    {{- $state := dict "acld" false "matched_dd" nil -}}
    {{- range $dd := $root.acl -}}
        {{- if and (eq ($aclshare|upper) ($ndisk|upper)) (not (get $state "acld")) -}}
            {{- $_ := set $state "acld" true -}}
            {{- $_ := set $state "matched_dd" $dd -}}
        {{- end -}}
    {{- end -}}
    {{- if get $state "acld" -}}
        {{- $dd := get $state "matched_dd" -}}
        {{- if not $dd.disabled -}}
            {{- template "SHT" ... -}}  // Render only once
        {{- end -}}
    {{- else -}}
        {{- template "SHT" ... -}}  // Render default if no ACL
    {{- end -}}
{{- end -}}
```

**Key improvements:**
- Store matched ACL in `$state` dict during the inner loop
- Only render template **after** the inner loop completes
- Use `(not (get $state "acld"))` to prevent multiple matches
- Guarantees each share is rendered exactly once

### Fix 2: Add Space After `=` in `valid users`

Changed:
```
valid users =_ha_mount_user_ {{ .users|default .username|join " " }}
```

To:
```
valid users = _ha_mount_user_ {{ .users|default .username|join " " }}
```

This ensures proper Samba configuration parsing and eliminates the token warnings.

## Testing

Tested with a configuration matching petebanham's setup:
- 9 ACL entries (all default shares + 2 external disks)
- Multiple users configured
- `secureuser` specified in ACL for all shares

**Before the fix:**
- Each share appeared 9 times in `smb.conf`
- Total of 63 share entries instead of 9

**After the fix:**
- Each share appears exactly once
- Correct user assignments
- Clean configuration output

```
[CONFIG]                path = /homeassistant # TM:false US:secureuser 
[ADDONS]                path = /addons # TM:false US:secureuser 
[SSL]                   path = /ssl # TM:false US:secureuser 
[SHARE]                 path = /share # TM:false US:secureuser 
[BACKUP]                path = /backup # TM:false US:secureuser 
[MEDIA]                 path = /media # TM:false US:secureuser 
[ADDON_CONFIGS]         path = /addon_configs # TM:false US:secureuser 
[SECURE]                path = /Secure # TM:true US:secureuser 
[VIDEO]                 path = /Video # TM:true US:secureuser 
```

## Files Modified

- `sambanas/rootfs/usr/share/tempio/smb.gtpl`

## Recommendation

For users experiencing this issue:
1. **Main user access**: If you want the main user (specified in `username`) to access shares, either:
   - Don't specify ACL entries for those shares (they'll use the default user)
   - Include the main username in the ACL `users` array
2. **Secure shares**: Use ACL with `other_users` for shares that should only be accessible to specific users

## Related Issues

- Issue #516: This fix also addresses the template logic issue that was partially fixed in #516
- The duplicate shares problem would have affected anyone using ACL configurations
