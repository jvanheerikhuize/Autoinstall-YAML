# Project Memory

## Project Identity
- **Repo**: `/home/jerry/Repos/Autoinstall-YAML`
- **Owner**: Jerry van Heerikhuize (@jvanheerikhuize)
- **Purpose**: Spec-driven Ubuntu autoinstall YAML configurations for developer workstations
- **Config format**: Ubuntu Autoinstall (subiquity) YAML, version 1

## Key Files
- `Autoinstall.yaml` — target output (not yet created; awaiting FEAT-0001 approval)
- `Autoinstall.example.yaml` — reference only, NOT the active config
- `specs/features/FEAT-0001-ubuntu-developer-workstation.yaml` — active spec (status: draft)
- `specs.config.yaml` — central spec registry
- `.ai/CONTEXT.md` — master AI context file

## Project Decisions
- **Mostly automated**: network + identity are interactive; everything else is automated
- **No hardcoded credentials**: identity section left blank, filled interactively
- **APT mirror**: always `archive.ubuntu.com`, GeoIP disabled, fallback: abort
- **Storage**: LVM layout
- **Shutdown**: poweroff (not reboot) after install
- **Source**: `ubuntu-desktop-minimal`

## Active Work
- FEAT-0001: Ubuntu Developer Workstation Autoinstall — spec is in `draft`, needs review → approved before implementation

## Spec Workflow
1. Draft spec in `specs/features/FEAT-XXXX-<name>.yaml`
2. Review → `status: review`
3. Approve → `status: approved`
4. Implement `Autoinstall.yaml` from acceptance criteria
5. Test in VM
6. Merge → `status: implemented`

## Important Rules (never violate)
- Never hardcode credentials in any YAML
- Only implement specs with `status: approved`
- All late-commands must use `curtin in-target`
- Do not modify `Autoinstall.example.yaml`

## User Preferences
- Spec-based development: no implementation without an approved spec
- Communication style: concise, no emojis
