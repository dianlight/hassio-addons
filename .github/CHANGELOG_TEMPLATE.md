# CHANGELOG Template for hassio-addons Projects

## Format for CHANGELOG.md entries

Use this template when updating CHANGELOG.md files in any project:

```markdown
## [Version] - YYYY-MM-DD

### Added
- New features or capabilities
- New configuration options
- New documentation sections

### Changed
- Modifications to existing features
- Updated dependencies
- Changed default values
- Updated documentation

### Fixed
- Bug fixes
- Security fixes
- Performance improvements
- Documentation corrections

### Removed
- Deprecated features removed
- Configuration options removed
- Dependencies removed

### Breaking Changes
- Changes that break existing configurations
- API changes
- Required migration steps

### Migration Notes
- Steps required to upgrade from previous version
- Configuration changes needed
- Data migration instructions
```

## Example Entry

```markdown
## [2.1.0] - 2025-01-15

### Added
- WSDD2 service integration for better Windows discovery
- Dynamic log level configuration based on add-on settings
- Interface filtering to exclude loopback interfaces

### Changed
- Updated S6 overlay configuration for improved service management
- Enhanced error handling in service startup scripts
- Improved documentation with more configuration examples

### Fixed
- Fixed WSDD2 argument parsing for workgroup configuration
- Resolved service dependency issues during startup
- Corrected log level mapping between add-on and WSDD2

### Breaking Changes
- WSDD2 configuration now requires explicit interface specification
- Log level configuration format changed from numeric to string values

### Migration Notes
- Update your configuration to use string log levels (info, debug, trace)
- Review interface configuration as loopback is now automatically excluded
```

## Guidelines

### Version Numbering
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes (backward compatible)

### Date Format
- Always use YYYY-MM-DD format
- Use the actual release date

### Description Guidelines
- Be specific about what changed
- Include relevant technical details
- Mention affected configuration options
- Reference issue numbers if applicable
- Use imperative mood ("Add feature" not "Added feature")

### Breaking Changes
- Always highlight breaking changes clearly
- Provide migration instructions
- Explain the impact on existing users
- Include examples of before/after configuration

### Project-Specific Notes

#### sambanas (Maintenance Mode)
- Only document critical bug fixes and security updates
- Include maintenance mode reminder in entries
- Direct users to sambanas2 for new features

#### sambanas2 (Active Development)
- Document all changes thoroughly
- Include performance impact notes
- Provide migration guidance from sambanas when relevant
- Document new service configurations

#### plex/RPiMySensor/addon-plex
- Focus on project-specific changes
- Include compatibility information
- Document hardware-specific requirements
- Keep entries isolated to the specific project
