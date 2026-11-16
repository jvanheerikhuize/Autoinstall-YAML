# Autoinstall YAML

One [Ubuntu Autoinstall](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html) file that installs a developer laptop unattended, except for the two things that are per machine: **network** and **identity**.

Short URL for the boot prompt: https://tinyurl.com/jvh-autoinstall

Target release is **Ubuntu 26.04 LTS (Resolute Raccoon)**; 24.04 LTS is the minimum. Reference machine: Dell Latitude 5400.

> [!IMPORTANT]
> As of 2026-11-16 no install has been verified end to end from this file. The `#cloud-config` header required for the deploy path below was only added in FEAT-0008. See [docs/ROADMAP.md](docs/ROADMAP.md).

This is **stage 1** of a three-stage machine rebuild. Stage 2 is [dotfiles](https://github.com/jvanheerikhuize/dotfiles) (apps and configuration), stage 3 is [agentic-workspace](https://github.com/jvanheerikhuize/agentic-workspace) (agent tooling). The split, the decisions and the rebuild runbook are in [docs/stateless-laptop-plan.md](docs/stateless-laptop-plan.md).

---

## Quick Deploy

1. Boot the Ubuntu Desktop ISO.
2. Press `e` to edit the GRUB entry.
3. Find the line starting with `linux` and append to the end of it:

```text
autoinstall cloud-config-url=https://tinyurl.com/jvh-autoinstall
```

4. Press `F10` to boot.

```mermaid
flowchart TD
    boot["Boot ISO with kernel parameter"] --> fetch["cloud-init fetches Autoinstall.yaml via TinyURL (GitHub raw)"]
    fetch --> net["Network (you act)"]
    fetch --> id["Identity: hostname + user (you act)"]
    net --> auto
    id --> auto
    auto["Fully automated: minimal desktop, LVM storage, hardware enablement, UFW, drivers + codecs, all updates"]
    auto --> reboot["Reboot, log in"]
```

The file starts with `#cloud-config` and a single top-level `autoinstall:` key. Both are required because the kernel parameter hands the file to cloud-init first, which only accepts payloads that begin with that header.

### One-time URL setup

The short URL points to the raw `Autoinstall.yaml` on `main`. Create it once on [tinyurl.com](https://tinyurl.com); custom aliases are free and never expire.

| Step | Action |
|------|--------|
| 1 | Paste `https://raw.githubusercontent.com/jvanheerikhuize/Autoinstall-YAML/main/Autoinstall.yaml` |
| 2 | Set the alias `jvh-autoinstall` |
| 3 | Make TinyURL |

---

## What stage 1 owns

Only what must exist before first login:

1. `ubuntu-desktop-minimal` base, LVM layout, all updates, drivers and codecs
2. Latitude 5400 hardware enablement: `intel-microcode`, `thermald`, `alsa-ucm-conf`, `bolt`, `fwupd-signed`
3. UFW enabled, Ubuntu's security snaps (`prompting-client`, `desktop-security-center`)
4. `git`, `curl`, `wget`, `build-essential` so stage 2 can be fetched

Editors, runtimes and GUI apps belong to stage 2. Items still in this file that violate that rule (`nodejs`, `npm`, the `code` snap, `gufw`) are scheduled to move; see the plan.

---

## Repository Structure

```text
├── Autoinstall.yaml          # The product; served via TinyURL
├── PURPOSE.md
├── docs/
│   ├── ROADMAP.md            # Grounded findings and status
│   └── stateless-laptop-plan.md
├── specs/
│   ├── features/             # FEAT-xxxx specs; one per change to Autoinstall.yaml
│   │   └── _template.yaml
│   └── schemas/feature-spec.schema.json
└── scripts/
    └── validate-specs.sh     # Local schema check (python3 + PyYAML + jsonschema)
```

---

## Current Status

| Spec | Title | Status |
|------|-------|--------|
| [FEAT-0001](specs/features/FEAT-0001-ubuntu-developer-workstation.yaml) | Ubuntu Developer Workstation Autoinstall | implemented |
| [FEAT-0004](specs/features/FEAT-0004-automated-locale-timezone.yaml) | Automated Locale, Keyboard, and Timezone | implemented |
| [FEAT-0005](specs/features/FEAT-0005-openscad-environment.yaml) | OpenSCAD 3D Modeling Environment | draft, to be closed (stage 2) |
| [FEAT-0006](specs/features/FEAT-0006-esp32-development-environment.yaml) | ESP32 Embedded Development Environment | draft, to move to a dotfiles profile |
| [FEAT-0007](specs/features/FEAT-0007-dotfiles-provisioning.yaml) | Dotfiles Provisioning | draft |
| [FEAT-0008](specs/features/FEAT-0008-cloud-init-delivery.yaml) | Deployable via cloud-init and verified end to end | review |

---

## Changing the file

Every change to `Autoinstall.yaml` starts with a spec:

1. Copy `specs/features/_template.yaml` to `specs/features/FEAT-xxxx-<name>.yaml`, status `draft`.
2. Run `scripts/validate-specs.sh`.
3. Open a PR with the spec and the YAML change together; merging is the approval. Set status `approved`.
4. Test in a VM (below). Set status `implemented`.

---

## Testing

Boot the Ubuntu Desktop 26.04 LTS ISO in a VirtualBox VM (at least 25 GB disk, 4 GB RAM) with the Quick Deploy kernel parameter. VirtualBox is the hypervisor on the reference machine; QEMU and multipass are not installed.

```bash
# Alternative: serve the YAML over HTTP (file must still start with #cloud-config) and boot with:
#   autoinstall ds=nocloud-net;s=http://<your-ip>/
```

After installation, verify:

1. All packages in the spec are present
2. Snaps are installed (`snap list`)
3. UFW is active (`sudo ufw status`)
4. The user account exists with sudo
5. LVM is in use (`sudo vgs`)

---

## References

1. [Ubuntu Autoinstall Reference](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
2. [Ubuntu Autoinstall Quick Start](https://canonical-subiquity.readthedocs-hosted.com/en/latest/howto/autoinstall-quickstart.html)
3. [cloud-init and autoinstall interaction](https://canonical-subiquity.readthedocs-hosted.com/en/latest/explanation/cloudinit-autoinstall-interaction.html)
4. [cloud-init kernel command line (`cloud-config-url`)](https://docs.cloud-init.io/en/latest/explanation/kernel-command-line.html)
5. [Subiquity on GitHub](https://github.com/canonical/subiquity)
