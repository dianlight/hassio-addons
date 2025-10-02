# Fix for Issue #516 - Regression in 12.5.0-nas1

## Problem Summary

After updating to version 12.5.0-nas1, users experienced mount failures when trying to use the Samba NAS addon with external disks. The issue occurred specifically when ACL (Access Control List) was not configured or set to an empty array.

### Symptoms
- Physical disk mount succeeded: `[11:12:36] INFO: Mount JellyfinMedia[ext4] Success!`
- Supervisor CIFS mount failed: `[11:12:37] ERROR: Got unexpected response from the API: Restarting JELLYFINMEDIA did not succeed`
- The addon appeared to work (smb.conf was generated) but external disks were not accessible via network shares

## Root Cause

The issue was introduced in version 12.5.0-nas1 when fixing issue #442 (ACL config not working with special characters in disk labels).

The fix for #442 added regex normalization code on lines 129-130 of `smb.gtpl`:

```go
{{- $ndisk := $disk | regexReplaceAll "[^A-Za-z0-9_/ ]" "_" | regexFind "[A-Za-z0-9_ ]+$" -}}
{{- $aclshare := $dd.share | regexReplaceAll "[^A-Za-z0-9_/ ]" "_" | regexFind "[A-Za-z0-9_ ]+$" -}}
```

This code correctly used the pipe operator (`|`) to pass values through the regex functions.

However, line 70 in the same file (inside the `SHT` template) had incorrect syntax:

```go
{{- $name := regexReplaceAll "[^A-Za-z0-9_/ ]" .share "_" | regexFind "[A-Za-z0-9_ ]+$" | upper -}}
```

### Why This Caused the Bug

When `regexReplaceAll` is called WITHOUT the pipe operator, the function signature is:
```go
regexReplaceAll(pattern, replacement, input)
```

So the incorrect code was interpreted as:
- pattern = `"[^A-Za-z0-9_/ ]"`
- replacement = `.share` (e.g., `"mnt/JellyfinMedia"`)
- input = `"_"`

This tried to find special characters in the string `"_"` and replace them with `"mnt/JellyfinMedia"`, which resulted in just `"_"` since there were no matches.

Then `regexFind "[A-Za-z0-9_ ]+$"` was applied to `"_"`, which matched `"_"`.

Finally, `upper` converted it to `"_"`.

**Result:** Share name became `[_]` instead of `[JELLYFINMEDIA]`!

### Why It Only Affected Non-ACL Configurations

When ACL is configured, the code takes a different path (lines 128-145) that uses the CORRECT regex syntax (lines 129-130). The share name is generated correctly in this case.

When ACL is NOT configured (empty array), the code goes to the non-ACL branch (lines 147-154), which calls the `SHT` template. The `SHT` template uses line 70, which had the incorrect syntax.

Therefore:
- **With ACL configured:** Works correctly (uses lines 129-130)
- **Without ACL configured:** Fails (uses line 70 with bug)

## The Fix

Change line 70 in `sambanas/rootfs/usr/share/tempio/smb.gtpl` from:

```go
{{- $name := regexReplaceAll "[^A-Za-z0-9_/ ]" .share "_" | regexFind "[A-Za-z0-9_ ]+$" | upper -}}
```

To:

```go
{{- $name := .share | regexReplaceAll "[^A-Za-z0-9_/ ]" "_" | regexFind "[A-Za-z0-9_ ]+$" | upper -}}
```

This makes the syntax consistent with lines 129-130 and ensures the correct function argument order.

### How the Fix Works

With the pipe operator, `.share` is passed as the input through the regex functions:

1. Input: `"mnt/JellyfinMedia"` (from `.share`)
2. `regexReplaceAll "[^A-Za-z0-9_/ ]" "_"` → `"mnt/JellyfinMedia"` (no special chars to replace)
3. `regexFind "[A-Za-z0-9_ ]+$"` → `"JellyfinMedia"` (extracts text after last `/`)
4. `upper` → `"JELLYFINMEDIA"`

**Result:** Share name is correctly generated as `[JELLYFINMEDIA]`!

## Testing

A test script (`test/test_no_acl_regression.sh`) was added to verify the fix:
- Creates a configuration without ACL settings
- Verifies that share names are correctly generated
- Detects the bug symptom (invalid `[_]` share name)
- Documents the root cause and solution

## Impact

This fix resolves the regression introduced in 12.5.0-nas1 and allows users to:
- Mount external disks without configuring ACL
- Use the default share configuration
- Access network shares via the supervisor mount system

## Related Issues

- **Issue #442:** ACL config not working with special characters (fixed in 12.5.0-nas1)
- **Issue #516:** Unable to mount disks when ACL is not set (fixed in 12.5.0-nas2 - this fix)
- **Issue #517:** Mount disks with special characters in label (separate issue, still open)

## Files Changed

1. `sambanas/rootfs/usr/share/tempio/smb.gtpl` - Fixed regex syntax on line 70
2. `sambanas/CHANGELOG.md` - Documented the fix
3. `sambanas/test/test_no_acl_regression.sh` - Added test script for verification
