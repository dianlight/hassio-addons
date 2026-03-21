# Sambanas2 Testing

This directory contains test scripts for the Sambanas2 Home Assistant add-on.

## Test Scripts

### Binary Upgrade Tests

Two test scripts validate the binary self-upgrade logic in `check-srat-update/run`:

#### 1. Unit Tests (`test-binary-upgrade.sh`)

Pure bash unit tests for version extraction, comparison, and upgrade decision logic.

**Requirements:**
- Basic bash utilities (`sort`, `sed`, `tr`)
- No compiler needed

**What it tests:**
- Semver validation (with/without 'v' prefix, prerelease tags)
- Version normalization
- Version comparison using `sort -V`
- Upgrade decision workflow

**Run it:**
```bash
./test-binary-upgrade.sh
```

**Example output:**
```
=== Testing semver validation ===
✓ Valid semver: 1.2.3
✓ Valid semver with 'v': v1.2.3
✓ Valid semver with prerelease: v2025.12.0-dev.8

=== Test Summary ===
Passed: 19
Failed: 0

All tests passed!
```

#### 2. Integration Tests (`test-binary-upgrade-integration.sh`)

End-to-end tests with actual ELF binaries containing `.note.metadata` sections.

**Requirements:**
- `gcc` (to compile test binaries)
- `objdump` (from binutils)

**What it tests:**
- Creating ELF binaries with embedded version metadata
- Extracting versions from `.note.metadata` using `objdump`
- Full upgrade workflow:
  - Newer versions ARE upgraded
  - Older versions are NOT upgraded
  - Version extraction from real binaries

**Run it:**
```bash
./test-binary-upgrade-integration.sh
```

If `gcc` is not available, the test will gracefully skip with a message.

**Example output:**
```
=== Creating mock binaries with versions ===
✓ Created source binary: srat-cli v2025.12.0
✓ Created upgrade binary: srat-cli v2025.12.1 (newer)

=== Simulating upgrade workflow ===
  Upgraded srat-cli from 2025.12.0 to 2025.12.1
  Skipped srat-server (1.4.0 not newer than 1.5.0)
✓ Correctly upgraded 1 binary (srat-cli)
✓ Correctly skipped 1 binary (srat-server - older version)

All integration tests passed!
```

## Other Test Scripts

### `buildLocal.sh`
Builds the add-on container image locally for testing.

### `runLocal.sh`
Runs the locally built add-on container with test configuration.

### `options.json`
Sample configuration for local testing.

## Running All Tests

To run both upgrade tests:

```bash
# Unit tests (always available)
./test-binary-upgrade.sh

# Integration tests (requires gcc + objdump)
./test-binary-upgrade-integration.sh
```

## CI/CD Integration

These tests can be added to CI pipelines:

```yaml
# Example GitHub Actions job
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Install dependencies
      run: sudo apt-get update && sudo apt-get install -y binutils gcc
    - name: Run unit tests
      run: ./sambanas2/test/test-binary-upgrade.sh
    - name: Run integration tests
      run: ./sambanas2/test/test-binary-upgrade-integration.sh
```

## Manual Testing with Real Binaries

To manually test the upgrade logic:

1. **Prepare test binaries with embedded versions:**
   ```bash
   # Your srat binaries should have .note.metadata sections
   objdump -s --section .note.metadata /usr/local/bin/srat-cli
   ```

2. **Set up upgrade directory:**
   ```bash
   mkdir -p /data/upgrade
   # Copy a newer version of srat-cli there
   cp /path/to/newer/srat-cli /data/upgrade/
   ```

3. **Trigger the upgrade check:**
   - Restart the add-on
   - Check logs for upgrade messages:
     ```
     [INFO] Upgraded srat-cli from 2025.12.0 to 2025.12.1
     ```

## Troubleshooting

**"objdump not found"**
- Install binutils: `apt-get install binutils` (Debian/Ubuntu) or `apk add binutils` (Alpine)

**"gcc not available"**
- Integration tests will skip gracefully
- Install gcc if you need full testing: `apt-get install gcc`

**Version extraction returns empty**
- Verify binary has `.note.metadata` section: `objdump -s --section .note.metadata <binary>`
- Check the section contains JSON with "version" field

**Versions not comparing correctly**
- Ensure versions follow semver: `MAJOR.MINOR.PATCH` (optional `v` prefix and `-prerelease`)
- Check `sort -V` behavior on your system (version-sort)
