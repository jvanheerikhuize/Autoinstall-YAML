# Improvement Plan & Roadmap

> Status: proposal. Nothing in this document has been implemented.
> Written 2026-07-24. Every finding below was verified against the repository,
> the reference machine (`jerry@Latitude-5400`), or Canonical's documentation.
> Claims that could not be verified are marked **unverified**.

---

## 0. Re-grounding, 2026-11-16

Everything below §0 is the 2026-07-24 analysis, kept verbatim as the baseline. This
section records what has changed since and what this pass did about it. Facts were
re-checked on the reference machine, on GitHub, and against the current subiquity and
cloud-init documentation.

### 0.1 What changed in the environment

| Fact | July 2026 | November 2026 |
|------|-----------|---------------|
| Reference OS | Ubuntu 24.04.4 LTS, kernel 7.0.0-28 | **Ubuntu 26.04.1 LTS (Resolute Raccoon)**, kernel 7.0.0-38, cloud-init 26.2 |
| Node.js | v20 on the machine, Node 18 in noble apt | **Node 22.22 in resolute apt** and on the machine; the `npm` apt package is removed on the machine |
| dotfiles repo | visibility **unverified**, remote is SSH | **public**, `install.sh` at root, last push 2026-07-25; `~/Repos/dotfiles` is no longer checked out |
| `desktop-security-center` snap | not installed | installed (`1/stable`) |
| `gufw`, `code`, `prompting-client` | not installed | still not installed |
| Spec Ingestion workflow | last run 2026-04-27 | **`disabled_inactivity`** on GitHub |
| Local spec validation | impossible (`ajv`, `jsonschema` absent) | **possible**: python3 `jsonschema` 4.19.2 and PyYAML 6.0.3 present; the `yamllint` shim is broken (orphaned venv) |
| `#cloud-config` header | missing | **still missing on `main`**; added on this branch |
| `openscad` apt candidate | 2021.01-6build4 (noble) | 2021.01-11 (resolute), still the 2021 release; `openscad-nightly` snap still in use |
| `arduino` snap | 1.8.19 | 1.8.19, rebuilt 2026-11-11, still the legacy IDE |
| Subiquity docs | ubuntu.com/server/docs | moved to canonical-subiquity.readthedocs-hosted.com; the quickstart now names 26.04 LTS as current |

The cloud-init requirement behind §2.1 was re-confirmed against the current cloud-init
documentation: "only cloud config user data starting with `#cloud-config` is supported"
for `cloud-config-url=`. The subiquity explanation page confirms the shape: header first,
then a single top-level `autoinstall:` key.

### 0.2 Status of the plan (section 3)

| # | Item | Status 2026-11-16 |
|---|------|-------------------|
| 1 | `#cloud-config` header | **Done** on this branch, governed by FEAT-0008 (status `review`) |
| 2 | One verified VM install | **Open**. Acceptance criteria written as FEAT-0008 AC-002/AC-003; needs a human at the VirtualBox console |
| 3 | FEAT-0007 dotfiles clone | **Unblocked**: repo is public. Real URL and logging now in the spec and the commented template; still untested, so still commented |
| 4 | Stage-1/stage-2 ADR | Open; `.ai/decisions/` still holds only the template |
| 5 | Refresh `.ai/CONTEXT.md` + README | **Done** (CPU, audio, installer, 26.04, Node 22, tests section, dates, status table, Mermaid diagrams) |
| 6 | CI triggers + local validation | **Done**: cron removed from `spec-ingestion.yml`; `scripts/validate-specs.sh` added (python only, no npm) |
| 7 | VirtualBox smoke-test script | Open, blocked by 2 |
| 8 | FEAT-0005 / FEAT-0006 | Grounding notes added to both specs; rewrite or close is still an owner decision |
| 9 | LUKS via interactive `storage` | Open, owner decision. The reference confirms `storage.layout.password` enables LUKS with the `lvm` layout, so the no-secrets rule still forces the interactive route |
| 10 | 24.04 vs 26.04 target | **Decided by reality**: the reference machine is on 26.04.1; docs now name 26.04 LTS as target, 24.04 as minimum |

### 0.3 Next exit criterion

Phase 1 is now one step from complete: boot the 26.04 Desktop ISO in VirtualBox with
the TinyURL parameter (after this branch merges, since the TinyURL serves `main`) and
record the checklist result under `docs/runbooks/`. Nothing else in this document
should move before that.

---

## 1. What this repository actually is

A **version-controlled Ubuntu autoinstall (subiquity) configuration for one specific
machine** — a Dell Latitude 5400 developer workstation — wrapped in a spec-governed
change process.

The product is a single file, `Autoinstall.yaml` (107 lines). Everything else exists to
control how that file changes:

| Layer | Files | Role |
|-------|-------|------|
| Product | `Autoinstall.yaml` | The thing that gets deployed |
| Governance | `specs/features/*.yaml`, `specs.config.yaml`, `specs/schemas/` | Draft → review → approved → implemented |
| AI context | `.ai/`, `.claude/CLAUDE.md`, `.cursorrules` | Instructions for AI assistants |
| Automation | `.github/workflows/`, `scripts/` | Spec validation and AI-assisted ingestion |

Deployment method (from `README.md`): boot an Ubuntu Desktop ISO, press `e` at GRUB,
append `autoinstall cloud-config-url=https://tinyurl.com/jvh-autoinstall`, press F10.
The install runs unattended except for two interactive sections — `network` and
`identity` — which exist because hostname, username and password must not be committed
to a public repo.

There is a **second, separate stage**: `~/Repos/dotfiles`, a mature shell provisioner
(`install.sh` + `src/*.sh` + profile inheritance `base → desktop → dev`) intended to run
after first boot. `FEAT-0007` is the spec that would wire stage 1 into stage 2. The
hook exists in `Autoinstall.yaml` but is commented out with placeholder values
(`GITHUB_USER/DOTFILES_REPO`).

**The gap between intent and reality:** the config describes a machine that has never
been built from it. See §2.2.

---

## 2. Grounded findings

### 2.1 P0 — The advertised deploy path is broken

`Autoinstall.yaml` line 1 is `autoinstall:`. There is no `#cloud-config` header.

The README advertises delivery via `cloud-config-url=`, which routes the file through
**cloud-init**, not directly into subiquity. Canonical's documentation is explicit:

> "Cloud config files must contain the `#cloud-config` header to be recognized as a
> valid cloud configuration data file."

Without that first line cloud-init will not recognise the payload, the `autoinstall`
key never reaches subiquity, and the installer falls back to interactive mode — the
exact failure mode that looks like "nothing happened".

The file is otherwise already correctly shaped for this path: it has the required
top-level `autoinstall:` key that cloud-init delivery expects. **The fix is one line.**

```diff
+#cloud-config
 autoinstall:
   version: 1
```

This does not break the alternative `ds=nocloud-net;s=` path documented under
"Testing the Autoinstall YAML" — that path also goes through cloud-init and wants the
same header.

### 2.2 P0 — The config has never been validated end to end

The reference machine is the target hardware, but it was **not** provisioned by this
config:

| Check | Config says | Machine has |
|-------|-------------|-------------|
| `gufw` | in `packages` | not installed |
| `code` snap | in `snaps` | not installed |
| `prompting-client` snap | in `snaps` | not installed |
| `desktop-security-center` snap | in `snaps` | not installed |
| OS | targets 24.04 | 24.04.4 LTS (noble), kernel 7.0.0-28-generic |

Additional snaps unrelated to the config are present. The conclusion is not that the
config is wrong — it's that **no evidence exists that it works**. Combined with §2.1,
the most likely history is: written, never booted.

Everything else in this document is lower priority than getting one successful VM
install on record.

### 2.3 P1 — Two provisioning stages with an undefined boundary

`Autoinstall.yaml` and `~/Repos/dotfiles/profiles/*.yaml` install overlapping sets:

| Package | Autoinstall.yaml | dotfiles profile |
|---------|------------------|------------------|
| `git`, `curl`, `wget`, `build-essential`, `ca-certificates`, `gnupg` | yes | `base` |
| `nodejs`, `npm` | yes | `dev` |
| `code` (snap) | yes | `desktop` |

Duplication is not itself harmful (apt is idempotent), but there is no written rule for
which stage owns what, so the two will drift apart. Proposed rule, to be recorded as an
ADR:

> **Stage 1 (`Autoinstall.yaml`) owns anything that must exist before first login** —
> hardware enablement, firmware, storage, firewall, the base toolchain needed to fetch
> stage 2. **Stage 2 (`dotfiles`) owns everything else** — editors, language runtimes,
> per-profile tooling, configuration.

Under that rule `nodejs`/`npm` and the `code` snap move out of `Autoinstall.yaml`.

### 2.4 P1 — FEAT-0007 rests on a false premise

The spec requires a **public** dotfiles repo cloned over HTTPS with no credentials.
The actual remote is SSH:

```
git@github.com:jvanheerikhuize/dotfiles.git
```

A `git clone` over SSH from a late-command runs before any key exists on the machine and
will fail. The `|| true` in the commented-out command means it fails *silently* — the
worst outcome, since the install still reports success.

Three viable options, in order of preference:

1. **Clone over HTTPS if the repo is public.** Requires confirming/making it public. No
   secrets involved, satisfies the no-credentials rule. (Whether the repo is currently
   public is **unverified** — the remote being SSH says nothing about visibility.)
2. **Drop the late-command; run stage 2 manually at first login.** Honest, zero risk,
   costs one command after install.
3. **First-boot systemd unit that waits for SSH keys.** More moving parts than this
   deserves.

Whichever is chosen, `|| true` should be replaced with something that logs to
`/var/log/` so a failure is discoverable.

### 2.5 P2 — Draft specs contradict the current archive

| Spec | Assumption | Reality |
|------|-----------|---------|
| FEAT-0005 | apt `openscad` from main/universe, "no third-party PPA required" | apt candidate is `2021.01-6build4` — over five years old. The reference machine actually runs the `openscad-nightly` **snap** from `latest/edge`. The spec would install *worse* software than the user already has. |
| FEAT-0006 | `arduino` snap | `latest/stable` is 1.8.19, published 2022-12-04 — the legacy 1.x IDE. Arduino IDE 2.x is the current line. |
| FEAT-0006 | user added to `dialout` | The user is genuinely **not** in `dialout` — this criterion is real and unmet. |

FEAT-0005 should be rewritten to match what actually works (the snap) or closed.
FEAT-0006's package choices need revisiting; its `dialout` criterion is sound.

### 2.6 P2 — Documentation drift

| Location | Says | Actual |
|----------|------|--------|
| `.ai/CONTEXT.md:49` | audio "requires sof-firmware + alsa-ucm-conf" | `sof-firmware` was removed in commit `4ba2342` as a nonexistent package; `Autoinstall.yaml:50` already documents the correction |
| `.ai/CONTEXT.md:46` | CPU "i5-8265U / i7-8665U" | i5-8365U |
| `.ai/CONTEXT.md:199` | tests "to be defined when FEAT-0001 is implemented" | FEAT-0001 is implemented; no `tests/` exists |
| `.ai/CONTEXT.md:288` | Last Updated 2026-02-24 | five months stale |
| `README.md:149-150` | FEAT-0001/0004 "approved" | `specs.config.yaml` says `implemented` |
| `Autoinstall.yaml:56` | "Ubuntu 24.04 ships Node 18 LTS" | noble ships Node 18.19 in apt, but the reference machine runs v20.20.2 — the comment is misleading about what you get |
| `specs.config.yaml`, `.ai/config.yaml` | `model: claude-sonnet-4-20250514` | superseded |

Individually trivial; collectively they mean an AI assistant reading `.ai/CONTEXT.md`
first (as `CLAUDE.md` instructs) starts from stale facts.

### 2.7 P2 — CI has decayed into a no-op

`.github/workflows/spec-ingestion.yml` runs on `cron: "0 9 * * 1-5"`. Every recorded run
succeeded in 16–37 seconds, i.e. found nothing to do. The last run was 2026-04-27,
consistent with GitHub's automatic disabling of scheduled workflows after 60 days of
repository inactivity.

A daily scheduled job that has never once done work is not automation, it's noise.
Convert to `workflow_dispatch` (+ optionally `pull_request`) and drop the schedule.

Separately, spec validation cannot currently be run locally: `ajv` is not installed and
Python `jsonschema` is absent. Contributors — human or AI — have no way to check a spec
before pushing.

### 2.8 P2 — No test harness, but VirtualBox is available

There is no `tests/` directory. Of the usual candidates, `qemu-system-x86_64`,
`cloud-localds` and `multipass` are all absent from the machine; **`VBoxManage` is
installed**. Any VM smoke-test harness should therefore target VirtualBox rather than
assume QEMU, which is what `.ai/CONTEXT.md:207-212` currently suggests.

Minimum useful harness: a script that boots the Ubuntu ISO in VirtualBox with the
kernel parameter, waits for reboot, then asserts the post-install checklist already
written in `README.md:202-207` (packages present, snaps installed, UFW active, LVM
present).

### 2.9 P3 — Full-disk encryption on a portable machine

`storage.layout.name: lvm` gives LVM without LUKS. This is a laptop; an unencrypted
disk is a meaningful exposure if it's lost.

Encryption cannot be fully automated here without putting a passphrase in the YAML,
which the project's own rules forbid ("No secrets in YAML"). The rule-respecting fix is
to add `storage` to `interactive-sections`, so the installer prompts for the layout and
passphrase. Cost: one more interactive step, from two to three.

This is a judgement call for the owner, not a defect — hence P3.

### 2.10 P3 — 26.04 LTS has shipped

Ubuntu 26.04 LTS "Resolute Raccoon" was released 2026-04-23. The config targets 24.04
and the reference machine is on 24.04.4. Nothing is broken, but the config's next
meaningful validation should decide whether it tracks 24.04 through its support window
or moves to 26.04. `refresh-installer.channel: stable/ubuntu-$REL` already handles the
release substitution correctly, so the change is mostly about which ISO gets tested.

---

## 3. Prioritised improvement plan

| # | Item | Priority | Effort | Blocked by |
|---|------|----------|--------|------------|
| 1 | Add `#cloud-config` header (§2.1) | P0 | 1 line | — |
| 2 | One successful VM install, recorded (§2.2) | P0 | half a day | 1 |
| 3 | Resolve FEAT-0007 dotfiles clone (§2.4) | P1 | small | decision on repo visibility |
| 4 | ADR defining the stage-1/stage-2 boundary (§2.3) | P1 | small | — |
| 5 | Refresh `.ai/CONTEXT.md` + README status table (§2.6) | P2 | small | 2 |
| 6 | Fix CI triggers; make local schema validation possible (§2.7) | P2 | small | — |
| 7 | VirtualBox smoke-test script (§2.8) | P2 | medium | 2 |
| 8 | Rewrite or close FEAT-0005; revise FEAT-0006 (§2.5) | P2 | medium | — |
| 9 | Decide on LUKS via interactive `storage` (§2.9) | P3 | small | owner decision |
| 10 | Decide 24.04 vs 26.04 target (§2.10) | P3 | — | owner decision |

Note on process: items 1, 3, 8 and 9 touch `Autoinstall.yaml` or spec status, which the
project's own rule ("Spec before YAML — no changes to `Autoinstall.yaml` without an
approved spec") governs. Item 1 is arguably a defect fix rather than a feature, but the
cleanest route is a small `FEAT-0008: deployable-via-cloud-init` spec that also captures
the VM validation criteria from item 2.

---

## 4. Roadmap

### Phase 1 — Make it work (items 1, 2)

The single goal is to move from "config that has never run" to "config with one
verified install behind it".

- Add the `#cloud-config` header.
- Boot the Ubuntu Desktop ISO in VirtualBox with the TinyURL kernel parameter.
- Walk the post-install checklist already in the README and record the result in the
  repo — a dated `docs/runbooks/` entry is enough.
- Fix whatever that install surfaces.

**Exit criterion:** a dated record of a successful unattended install, listing which
checklist items passed.

### Phase 2 — Make it honest (items 3, 4, 5)

Close the gap between what the documentation claims and what the repo does.

- Decide the dotfiles clone approach; either implement it properly with logging or
  delete the commented-out placeholder and document the manual step.
- Write the stage-1/stage-2 ADR and move packages accordingly.
- Update `.ai/CONTEXT.md` (sof-firmware, CPU model, tests section, date) and the README
  status table.

**Exit criterion:** no statement in `.ai/` or `README.md` contradicts the repo or the
reference machine.

### Phase 3 — Make it repeatable (items 6, 7)

- Replace the dead cron trigger with `workflow_dispatch` / `pull_request`.
- Add a documented way to validate specs locally.
- Add the VirtualBox smoke-test script and wire the checklist assertions into it.

**Exit criterion:** a full validation cycle can be run from a clean checkout with one
command, and CI runs only when there is something to do.

### Phase 4 — Make it broader (items 8, 9, 10)

Only worth starting once Phases 1–3 hold.

- Rewrite FEAT-0005 around the snap, or close it as already satisfied outside the config.
- Revise FEAT-0006's package choices; keep the `dialout` criterion.
- Owner decisions: LUKS via interactive `storage`; 24.04 vs 26.04 target.

**Exit criterion:** every spec in `specs/features/` is either `implemented` or
`deprecated` — none left indefinitely in `draft`.

---

## 5. What was checked

Repository: all of `Autoinstall.yaml`, `README.md`, `.ai/CONTEXT.md`, `specs.config.yaml`,
`specs/features/FEAT-0005/0006/0007`, `.github/workflows/`, git log, GitHub Actions run
history.

Reference machine: `/etc/os-release`, `uname -r`, `dmidecode`/CPU model, `dpkg -l` for
each configured package, `snap list`, `apt-cache policy openscad`, `snap info arduino`,
`groups`, `node --version`, `lsblk`, presence of `qemu-system-x86_64` / `cloud-localds` /
`multipass` / `VBoxManage` / `ajv` / Python `jsonschema`.

Second repository: `~/Repos/dotfiles` — `install.sh`, `src/*.sh`, `profiles/*.yaml`,
`git remote -v`.

External: Canonical autoinstall reference and the "Providing autoinstall configuration"
tutorial (for the `#cloud-config` requirement); Ubuntu 26.04 release date.

One hypothesis was checked and **discarded**: that `channel: stable/ubuntu-$REL` was
broken because `$REL` would not be substituted. Canonical's reference confirms `$REL`
*is* substituted at runtime and that this value is the documented default. It is correct
as written.
