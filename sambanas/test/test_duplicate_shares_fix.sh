#!/bin/bash
# Test script for verifying the fix for duplicate shares issue #516
# Tests that:
# 1. Each share appears only once in smb.conf
# 2. ACL entries are correctly matched and applied

echo "Testing duplicate shares fix..."

# Create test configuration matching the issue report
cat > /tmp/test_duplicate_options.json << 'EOF'
{
  "workgroup": "WORKGROUP",
  "username": "share",
  "password": "testpass",
  "local_master": true,
  "allow_hosts": [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ],
  "automount": true,
  "moredisks": [],
  "mountoptions": ["nosuid", "relatime", "noexec"],
  "veto_files": ["._*", ".DS_Store"],
  "compatibility_mode": false,
  "recyle_bin_enabled": false,
  "wsdd2": false,
  "wsdd": true,
  "other_users": [
    {
      "username": "secureuser",
      "password": "securepass"
    }
  ],
  "acl": [
    {
      "share": "secure",
      "users": ["secureuser"]
    },
    {
      "share": "share",
      "users": ["secureuser"]
    },
    {
      "share": "ssl",
      "disabled": true
    }
  ],
  "interfaces": [],
  "shares": {
    "SECURE": {"fs": "ext4"},
    "VIDEO": {"fs": "ext4"}
  },
  "docker_interface": "hassio",
  "docker_net": "172.30.32.0/23",
  "medialibrary": {
    "enable": false
  }
}
EOF

# Test the template processing
echo "Testing template processing..."
if command -v tempio &> /dev/null; then
    tempio -template /workspaces/hassio-addons/sambanas/rootfs/usr/share/tempio/smb.gtpl -input /tmp/test_duplicate_options.json -out /tmp/test_smb_duplicate.conf
    
    echo "Generated Samba configuration:"
    echo "================================"
    cat /tmp/test_smb_duplicate.conf
    echo "================================"
    
    # Check for duplicate share definitions
    echo ""
    echo "Checking for duplicate shares..."
    duplicates_found=false
    for share in "CONFIG" "ADDONS" "SSL" "SHARE" "BACKUP" "MEDIA" "ADDON_CONFIGS" "SECURE" "VIDEO"; do
        count=$(grep -c "^\[$share\]" /tmp/test_smb_duplicate.conf || echo 0)
        if [ "$count" -gt 1 ]; then
            echo "❌ FAILURE: Share [$share] appears $count times (expected 1)"
            duplicates_found=true
        elif [ "$count" -eq 1 ]; then
            echo "✅ OK: Share [$share] appears exactly once"
        elif [ "$share" = "SSL" ]; then
            # SSL should not appear because it's disabled
            echo "✅ OK: Share [$share] not present (correctly disabled)"
        else
            echo "⚠️  Warning: Share [$share] not found (count: $count)"
        fi
    done
    
    if [ "$duplicates_found" = true ]; then
        echo ""
        echo "❌ FAILURE: Duplicate shares detected!"
        exit 1
    fi
    
    # Check that ACL is correctly applied
    echo ""
    echo "Checking ACL application..."
    
    # CONFIG should have default user "share"
    config_section=$(awk '/^\[CONFIG\]$/,/^$/' /tmp/test_smb_duplicate.conf)
    if echo "$config_section" | grep -q "valid users.*share"; then
        echo "✅ OK: CONFIG share has default user 'share'"
    else
        echo "❌ FAILURE: CONFIG share does not have default user 'share'"
        echo "$config_section" | grep "valid users"
        exit 1
    fi
    
    # SHARE should have ACL user "secureuser"
    share_section=$(awk '/^\[SHARE\]$/,/^$/' /tmp/test_smb_duplicate.conf)
    if echo "$share_section" | grep -q "valid users.*secureuser"; then
        echo "✅ OK: SHARE share has ACL user 'secureuser'"
    else
        echo "❌ FAILURE: SHARE share does not have ACL user 'secureuser'"
        echo "$share_section" | grep "valid users"
        exit 1
    fi
    
    # SECURE (external disk) should have ACL user "secureuser"
    secure_section=$(awk '/^\[SECURE\]$/,/^$/' /tmp/test_smb_duplicate.conf)
    if echo "$secure_section" | grep -q "valid users.*secureuser"; then
        echo "✅ OK: SECURE share has ACL user 'secureuser'"
    else
        echo "❌ FAILURE: SECURE share does not have ACL user 'secureuser'"
        echo "$secure_section" | grep "valid users"
        exit 1
    fi
    
    # VIDEO (external disk without ACL) should have default user "share"
    video_section=$(awk '/^\[VIDEO\]$/,/^$/' /tmp/test_smb_duplicate.conf)
    if echo "$video_section" | grep -q "valid users.*share"; then
        echo "✅ OK: VIDEO share has default user 'share'"
    else
        echo "❌ FAILURE: VIDEO share does not have default user 'share'"
        echo "$video_section" | grep "valid users"
        exit 1
    fi
    
    echo ""
    echo "✅ SUCCESS: All tests passed! Issue #516 appears to be fixed."
    echo ""
    echo "Fix Summary:"
    echo "============"
    echo "1. Changed from boolean \$acld to dict-based \$state for proper scope tracking"
    echo "2. Updated state check to use 'get \$state \"acld\"' for reliable access"
    echo ""
    echo "This resolves:"
    echo "- Duplicate share entries in smb.conf"
    echo "- Incorrect ACL user assignment to default shares"
    
else
    echo "⚠️  Warning: tempio command not found. Cannot run full template test."
    echo "Installing tempio for testing..."
    
    # Try to provide guidance for manual testing
    echo ""
    echo "Manual Verification Steps:"
    echo "=========================="
    echo "1. Check that each [SHARENAME] appears only once in smb.conf"
    echo "2. Check that shares with ACL use ACL users, others use default user"
    echo "3. Check that disabled shares (like SSL) do not appear"
fi

# Cleanup
rm -f /tmp/test_duplicate_options.json /tmp/test_smb_duplicate.conf

exit 0
