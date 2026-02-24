# System Architecture

> **For AI Assistants**: This document defines HOW the autoinstall system is structured. For WHAT it does, see `../specs/SPEC.md`. For WHY decisions were made, see `../decisions/`.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Status | Active |
| Last Updated | 2026-02-24 |
| Owner | Jerry van Heerikhuize |

---

## 1. Architecture Overview

### 1.1 System Context

This is a **configuration-driven** project, not an application. The "system" is the Ubuntu Autoinstall pipeline: a YAML file consumed by the subiquity installer to provision a machine without manual intervention.

```
┌─────────────────────────────────────────────────────────────┐
│                     Operator / Engineer                      │
│            (provides ISO + autoinstall YAML)                │
└──────────────────────────┬──────────────────────────────────┘
                           │  boot + autoinstall YAML
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Ubuntu Subiquity Installer                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  autoinstall │  │   storage    │  │  late-commands   │  │
│  │  YAML parser │  │  (curtin)    │  │  (curtin chroot) │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │  writes to disk
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Installed Ubuntu System                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   GNOME      │  │  Developer   │  │  Security        │  │
│  │   Desktop    │  │  Tools       │  │  (UFW, drivers)  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Architecture Style

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| Overall style | Declarative configuration | Subiquity processes YAML; no imperative code except late-commands |
| Interactivity | Mostly automated | Network and identity are interactive; all else is automated |
| Storage | LVM | Flexible partition resizing post-install; industry standard for managed workstations |
| Post-install | curtin in-target | Chroot-safe execution, no network dependency after packages are staged |

---

## 2. Autoinstall YAML Structure

### 2.1 Section Map

The `Autoinstall.yaml` file is organized into the sections below. Sections marked **interactive** pause the installer for user input.

```
autoinstall:
  version: 1                   # Always 1 for current subiquity
  │
  ├── refresh-installer         # Self-update before proceeding
  ├── oem                       # OEM kernel auto-detection
  ├── locale                    # System locale (en_US.UTF-8)
  ├── keyboard                  # Keyboard layout (us)
  ├── timezone                  # System timezone (Europe/Amsterdam)
  ├── interactive-sections      # [network, identity] — pauses for user
  ├── source                    # ubuntu-desktop-minimal
  ├── storage                   # LVM layout
  ├── identity                  # hostname/user (interactive, values left blank)
  ├── packages                  # APT packages
  ├── snaps                     # Snap packages
  ├── debconf-selections        # Pre-seed debconf (e.g. UFW enable)
  ├── drivers                   # Third-party drivers
  ├── codecs                    # Restricted media codecs
  ├── apt                       # Mirror config, GeoIP off
  ├── updates                   # all (security + general)
  ├── late-commands             # Post-install chroot commands
  └── shutdown                  # reboot after install
```

### 2.2 Section Descriptions

| Section | Purpose | Automated? |
|---------|---------|-----------|
| `version` | Declares subiquity config version | Yes |
| `refresh-installer` | Updates installer from `stable/ubuntu-$REL` channel | Yes |
| `oem` | Auto-installs OEM kernel if hardware recommends it | Yes |
| `locale` | Sets system locale to `en_US.UTF-8` | Yes |
| `keyboard` | Sets keyboard layout to `us` | Yes |
| `timezone` | Sets system timezone to `Europe/Amsterdam` | Yes |
| `interactive-sections` | Lists sections that pause for user input | — |
| `source` | Selects `ubuntu-desktop-minimal` as installation source | Yes |
| `storage` | Configures LVM disk layout | Yes |
| `identity` | Hostname, username, password — left blank for interactive fill | Interactive |
| `network` | Network interface configuration | Interactive |
| `packages` | APT packages installed during setup | Yes |
| `snaps` | Snap packages installed during setup | Yes |
| `debconf-selections` | Pre-seeds debconf answers (e.g. UFW enable) | Yes |
| `drivers` | Enables third-party driver installation | Yes |
| `codecs` | Enables restricted media codec installation | Yes |
| `apt` | Configures APT mirror; disables GeoIP | Yes |
| `updates` | Applies security + general updates pre-boot | Yes |
| `late-commands` | Runs arbitrary commands in the chroot after install | Yes |
| `shutdown` | Reboots the machine after installation completes | Yes |

---

## 3. Software Architecture

### 3.1 Package Strategy

Packages are divided into three tiers:

| Tier | Mechanism | Examples | When installed |
|------|-----------|---------|----------------|
| Base OS | `source: ubuntu-desktop-minimal` | GNOME, systemd, NetworkManager | During partitioning phase |
| APT packages | `packages:` section | git, curl, build-essential, gufw | Package installation phase |
| Snap packages | `snaps:` section | VS Code, prompting-client, desktop-security-center | Snap installation phase |
| Post-install | `late-commands:` | (extensible — future specs) | After base system is written |

### 3.2 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      UFW Firewall                           │
│  Default policy: deny inbound / allow outbound              │
│  Enabled via: debconf-selections + late-commands            │
├─────────────────────────────────────────────────────────────┤
│                  Third-Party Drivers                        │
│  install: true (GPU, Wi-Fi, etc.)                           │
├─────────────────────────────────────────────────────────────┤
│                   No Embedded Secrets                       │
│  identity section left blank — filled interactively        │
├─────────────────────────────────────────────────────────────┤
│                   APT Mirror Integrity                      │
│  fallback: abort — never install from unknown mirrors       │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 APT Mirror Architecture

```
Primary (amd64, i386):
  http://archive.ubuntu.com/ubuntu

ARM / other arches:
  http://ports.ubuntu.com/ubuntu-ports

GeoIP:         disabled (geoip: false)
Fallback:      abort
```

Rationale: GeoIP is disabled to ensure deterministic mirror selection across different network environments (corporate offices, home, VPN). The canonical archive is always used.

---

## 4. Interactive vs. Automated Sections

### 4.1 Interactive (user must act)

| Section | Why interactive |
|---------|----------------|
| `network` | Each machine has a different network environment (DHCP, static, VPN, proxy) |
| `identity` | Each machine needs a unique hostname and user credentials — hardcoding is a security risk |

### 4.2 Automated (no user action)

All other sections are fully automated. The machine can be left unattended from the moment the network and identity steps are confirmed.

---

## 5. Late Commands Architecture

Late commands run via `curtin in-target -- <command>` which executes in a chroot of the installed system. This ensures:
- Commands run against the target system, not the live installer environment
- APT, systemctl, and other system tools operate on the installed OS
- Network is available during late-commands if needed

Current late-commands scope is defined per spec. Future specs may extend this section.

---

## 6. Lifecycle

```
[Spec drafted] → [Spec reviewed] → [Spec approved]
                                          │
                                          ▼
                               [Autoinstall.yaml created]
                                          │
                                          ▼
                               [Tested in VM]
                                          │
                                     ┌────┴────┐
                                     │  Pass?  │
                                     └────┬────┘
                               Yes ───────┘───── No → Fix YAML
                                          │
                                          ▼
                               [Merged to main]
                                          │
                                          ▼
                               [Used to provision machines]
```

---

## 7. Development Standards

### 7.1 YAML Conventions

See [PATTERNS.md](PATTERNS.md) for detailed YAML style guidelines. Key rules:

- 2-space indentation throughout
- Single quotes for string values where quoting is needed
- Comments above each top-level section explaining intent
- No trailing whitespace

### 7.2 Cross-Cutting Concerns

| Concern | Implementation |
|---------|----------------|
| Secrets | Never in YAML — identity section left blank |
| Idempotency | subiquity handles idempotency; late-commands should be idempotent where possible |
| Error handling | `|| true` only for non-critical late-commands that may fail gracefully |
| Logging | Installer logs at `/var/log/installer/` on the installed system |

---

## 8. Appendix

### A. Technology Reference

| Technology | Version | Notes |
|------------|---------|-------|
| Ubuntu | 24.04 LTS (Noble) | Minimum supported version |
| Subiquity | Bundled with ISO | Autoinstall v1 format |
| Curtin | Bundled with subiquity | Storage and late-commands executor |
| LVM | System default | Logical Volume Manager for storage |

### B. Architecture Decision Records

See `../decisions/` for detailed ADRs.

### C. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-24 | Jerry van Heerikhuize | Initial version |
