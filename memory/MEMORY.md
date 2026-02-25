# Project Memory

## Developer Domains
- **JavaScript / Node.js**: primary development stack (nodejs + npm installed)
- **OpenSCAD**: parametric 3D modeling (FEAT-0005)
- **ESP32 / embedded**: firmware development with Arduino/PlatformIO (FEAT-0006)
  - Requires `dialout` group membership for USB serial (CP210x / CH340)
  - PlatformIO is a VS Code extension (post-install)

## Target Hardware
- **Model**: Dell Inc. Latitude 5400
- **CPU**: Intel 8th Gen (Whiskey Lake) — Core i5-8265U / i7-8665U
- **GPU**: Intel UHD Graphics 620 (i915 — in kernel)
- **Wi-Fi**: Intel Wireless-AC 9560 (iwlwifi — in kernel, firmware via linux-firmware)
- **Audio**: Realtek ALC256 — requires `alsa-ucm-conf` for mic/speakers; SOF firmware is bundled in `linux-firmware` (no separate package — `sof-firmware` does not exist in Ubuntu)
- **Fingerprint**: Broadcom BCM58200 — handled via OEM stack (`oem: install: auto`)
- **Thunderbolt**: Thunderbolt 3 — managed by `bolt`
- **Firmware updates**: Dell LVFS via `fwupd` + `fwupd-signed`

## Project Identity
- **Repo**: `/home/jerry/Repos/Autoinstall-YAML`
- **Owner**: Jerry van Heerikhuize (@jvanheerikhuize)
- **Purpose**: Spec-driven Ubuntu autoinstall YAML configurations for developer workstations
- **Config format**: Ubuntu Autoinstall (subiquity) YAML, version 1

## Key Files
- `Autoinstall.yaml` — active autoinstall config (implements FEAT-0001 + FEAT-0004)
- `specs/features/FEAT-0001-ubuntu-developer-workstation.yaml` — base workstation spec (status: implemented)
- `specs/features/FEAT-0004-automated-locale-timezone.yaml` — locale/timezone spec (status: implemented)
- `specs/features/FEAT-0005-openscad-environment.yaml` — OpenSCAD spec (status: draft)
- `specs/features/FEAT-0006-esp32-development-environment.yaml` — ESP32 spec (status: draft)
- `specs.config.yaml` — central spec registry
- `.ai/CONTEXT.md` — master AI context file

## Project Decisions
- **Mostly automated**: network + identity are interactive; everything else is automated
- **No hardcoded credentials**: identity section left blank, filled interactively
- **APT mirror**: always `archive.ubuntu.com`, GeoIP disabled, fallback: abort
- **Storage**: LVM layout
- **Shutdown**: reboot after install
- **Source**: `ubuntu-desktop-minimal`
- **Shell**: bash (Ubuntu default, no change)
- **Docker**: not included (install manually if needed later)
- **SSH server**: not included (desktop machine, no remote access needed)
- **Node.js**: nodejs + npm from Ubuntu archive (Node 18 LTS); nvm post-install if multiple versions needed

## Active Work
- FEAT-0001: Ubuntu Developer Workstation Autoinstall — status: implemented
- FEAT-0004: Automated Locale/Timezone — status: implemented

## Spec Workflow
1. Draft spec in `specs/features/FEAT-XXXX-<name>.yaml`
2. Review → `status: review`
3. Approve → `status: approved`
4. Implement `Autoinstall.yaml` from acceptance criteria
5. Test in VM
6. Merge → `status: implemented`

## Verified Package List (Ubuntu 24.04 Noble)
All packages confirmed in apt cache as of 2026-02-24:
`git`, `curl`, `wget`, `build-essential`, `ca-certificates`, `gnupg`, `gufw`,
`intel-microcode`, `thermald`, `alsa-ucm-conf`, `bolt`, `fwupd-signed`, `nodejs` (18.19.1 LTS), `npm`
- `sof-firmware` does NOT exist in Ubuntu — SOF is bundled in `linux-firmware`

Snaps confirmed available: `code`, `prompting-client`, `desktop-security-center`
- `code` (VS Code) is a **classic snap** — requires `classic: true` in the autoinstall YAML or `snap install code` fails
- `prompting-client` and `desktop-security-center` use strict confinement — no `classic: true` needed

`ufw/enable` is a valid debconf key for the `ufw` package (Template confirmed).

## Identity Section Behavior
- The `identity:` block must be **absent** from the YAML entirely, not present with blank strings
- Blank strings `""` cause subiquity to skip the interactive identity prompt on ubuntu-desktop-minimal
- Only `interactive-sections: [network, identity]` is needed — no `identity:` block

## Important Rules (never violate)
- Never hardcode credentials in any YAML
- Only implement specs with `status: approved`
- All late-commands must use `curtin in-target`
- Never add an `identity:` block with blank values — omit the block entirely

## User Preferences
- Spec-based development: no implementation without an approved spec
- Communication style: concise, no emojis
