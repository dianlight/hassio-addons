---
name: addon-validate
description: "Validate a Home Assistant add-on change with config checks, hadolint, and build prechecks. Use for Dockerfile/config/build updates in hassio-addons."
argument-hint: "Addon folder name (for example: sambanas2)"
---
# Add-on Validation Workflow

## When To Use

Use this skill when a task changes any of the following:
- `config.yaml` or `config.json`
- `Dockerfile`
- startup/service scripts under `rootfs/`
- build metadata (`build.yaml`, image tags, architecture list)

## Procedure

1. Confirm target add-on directory exists and contains `config.yaml` or `config.json`.
2. Initialize submodules:
   - `git submodule update --init --recursive`
3. Validate config format:
   - YAML add-on: `yq -e '.name, .version, .arch, .image' <addon>/config.yaml`
   - JSON add-on: `jq -e '.name, .version, .arch' <addon>/config.json`
4. Lint Dockerfile:
   - `hadolint -c <addon>/.hadolint.yaml <addon>/Dockerfile`
5. Run local build precheck (example single arch):
   - `check=no archs=--aarch64 ./build.sh <addon>`

## Critical Guardrails

- Do not cancel builder runs once started.
- Build and image pull phases can take 15-45 minutes per architecture.
- Prefer 60+ minute timeouts for build commands.

## Completion Checklist

- Config validation passed.
- Dockerfile lint passed.
- Build command executed or a blocker is clearly reported.
- Related docs in the same add-on are updated when behavior changed.
