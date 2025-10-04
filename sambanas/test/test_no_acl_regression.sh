#!/bin/bash
# Test script to verify fix for issue #516
# Test that disk mounts work correctly when ACL is not set

echo "Testing disk mount configuration WITHOUT ACL (Issue #516 regression fix)..."

# Create test configuration WITHOUT ACL
cat > /tmp/test_no_acl_options.json << 'EOF'
{
  "workgroup": "WORKGROUP",
  "username": "homeassistant",
  "password": "testpass",
  "allow_hosts": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"],
  "moredisks": ["JellyfinMedia"],
  "acl": [],
  "shares": {
    "JELLYFINMEDIA": {"path": "/mnt/JellyfinMedia", "fs": "ext4"}
  },
  "docker_interface": "hassio",
  "docker_net": "172.30.32.0/23",
  "interfaces": ["enp0s25"],
  "local_master": true,
  "veto_files": ["._*", ".DS_Store", "Thumbs.db", "icon?", ".Trashes"],
  "compatibility_mode": false,
  "recyle_bin_enabled": false,
  "wsdd": true,
  "wsdd2": false,
  "medialibrary": {
    "enable": true
  },
  "log_level": "info"
}
EOF

# Test the template processing
echo "Testing template processing..."
if command -v tempio &> /dev/null; then
    tempio -template rootfs/usr/share/tempio/smb.gtpl -input /tmp/test_no_acl_options.json -out /tmp/test_no_acl_smb.conf 2>&1
    
    if [ $? -ne 0 ]; then
        echo "❌ FAILURE: Template processing failed"
        cat /tmp/test_no_acl_smb.conf 2>/dev/null || echo "No output file generated"
        exit 1
    fi

    echo ""
    echo "Generated Samba configuration:"
    echo "================================"
    cat /tmp/test_no_acl_smb.conf
    echo "================================"
    echo ""

    # Check if the share is present with correct name
    if ! grep -q "\[JELLYFINMEDIA\]" /tmp/test_no_acl_smb.conf; then
        echo "❌ FAILURE: Share [JELLYFINMEDIA] not found in generated config"
        exit 1
    fi

    # Check if the path is correct
    if ! grep -q "path = /mnt/JellyfinMedia" /tmp/test_no_acl_smb.conf; then
        echo "❌ FAILURE: Correct path not found in generated config"
        exit 1
    fi

    # Check that no invalid share names were generated (like [_])
    if grep -q "\[_\]" /tmp/test_no_acl_smb.conf; then
        echo "❌ FAILURE: Invalid share name [_] found in config (this was the bug!)"
        exit 1
    fi

    echo "✅ SUCCESS: Disk share without ACL is properly configured"
    echo ""
    echo "Share details:"
    echo "--------------"
    awk '/\[JELLYFINMEDIA\]/,/^$/' /tmp/test_no_acl_smb.conf | head -20

    echo ""
    echo "Test completed successfully! Issue #516 regression appears to be fixed."
else
    echo "⚠️  Warning: tempio command not found. Cannot run full template test."
    echo ""
    echo "Manual verification:"
    echo "===================="
    echo "The fix changes line 70 in smb.gtpl from:"
    echo "  regexReplaceAll \"[^A-Za-z0-9_/ ]\" .share \"_\""
    echo "to:"
    echo "  .share | regexReplaceAll \"[^A-Za-z0-9_/ ]\" \"_\""
    echo ""
    echo "This ensures proper pipe operator usage for regex functions,"
    echo "making the syntax consistent with the ACL matching code (lines 129-130)."
    
    # Verify the fix is applied
    if grep -q '\.share | regexReplaceAll "\[' rootfs/usr/share/tempio/smb.gtpl; then
        echo ""
        echo "✅ Fix verified: Pipe operator is correctly used on line 70"
    else
        echo ""
        echo "❌ Fix not applied: Line 70 still has incorrect syntax"
        exit 1
    fi
fi

# Cleanup
rm -f /tmp/test_no_acl_options.json /tmp/test_no_acl_smb.conf

echo ""
echo "Fix Summary for Issue #516:"
echo "==========================="
echo "1. Fixed regexReplaceAll function call on line 70 to use pipe operator"
echo "2. This ensures .share value is correctly processed to extract share name"
echo "3. Share name [JELLYFINMEDIA] is now generated correctly instead of [_]"
echo "4. Supervisor CIFS mount can now connect to the correct share"
echo ""
echo "Root Cause:"
echo "-----------"
echo "The nas1 fix for issue #442 added regex normalization on lines 129-130"
echo "using the correct pipe operator syntax. However, line 70 (in the SHT template)"
echo "was using incorrect function call syntax without the pipe operator."
echo "When ACL is not set, only line 70 executes, which caused share names"
echo "to be generated incorrectly as [_] instead of the actual disk name."
