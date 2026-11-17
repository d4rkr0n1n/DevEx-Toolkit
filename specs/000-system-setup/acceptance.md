# 000 System Setup: Acceptance Criteria

Each criterion maps to requirements in [`spec.md`](spec.md). Phase 0 is accepted when every criterion passes on every platform in the supported matrix (spec NFR-PORT-1), unless the criterion is marked with a platform.

"Fixture" means a controlled test environment (temp directories, a crafted PATH, fake executables that print known output). Fake executables let criteria be verified without the real tools being installed.

## AC-OS: OS detection

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-OS-1 | Any supported machine | `devex doctor --json` runs | `host.os.family` is one of `windows`, `macos`, `linux` and matches the actual OS | FR-OS-1 |
| AC-OS-2 | Windows 11 | scan runs | `host.os.build` equals the build number reported by the OS, and `host.os.version` equals the display version (e.g. `24H2`) | FR-OS-2 |
| AC-OS-3 | Linux with `/etc/os-release` containing `ID=ubuntu`, `VERSION_ID="24.04"` | scan runs | `host.os.distro.id == "ubuntu"` and `host.os.distro.versionId == "24.04"` | FR-OS-2 |
| AC-OS-4 | Linux fixture with no os-release file | scan runs | `host.os.distro` fields are `null`; scan exits 0 or 1 (not 3); no `scanErrors` entry for OS detection | FR-OS-2, NFR-ROB-1 |
| AC-OS-5 | arm64 machine | scan runs | `host.arch.normalized == "arm64"` and `host.arch.raw` is non-empty | FR-OS-4 |
| AC-OS-6 | macOS arm64, CLI running under Rosetta 2 | scan runs | `host.emulated == true` | FR-OS-5 |
| AC-OS-7 | WSL 2 distro | scan runs | `host.os.family == "linux"`, `host.context.wsl.version == 2` | FR-OS-6 |
| AC-OS-8 | `GITHUB_ACTIONS=true` set | scan runs | `host.context.ci` identifies GitHub Actions | FR-OS-6 |

## AC-SH: Shell detection

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-SH-1 | CLI launched from bash | scan runs | `shells.current.name == "bash"` and `detectionMethod == "parent-process"` | FR-SH-1, FR-SH-4 |
| AC-SH-2 | CLI launched from PowerShell 7 and, separately, from Windows PowerShell 5.1 | scan runs | `shells.current.name` is `pwsh` and `powershell` respectively | FR-SH-1, FR-SH-3 |
| AC-SH-3 | CLI launched directly by a non-shell process (e.g. a test harness spawning it without a shell) | scan runs | `shells.current` is `null` and the human output states the current shell could not be determined | FR-SH-1 |
| AC-SH-4 | Unix user whose login shell is zsh, CLI launched from bash | scan runs | `shells.current.name == "bash"`, `shells.default.name == "zsh"` | FR-SH-1, FR-SH-2 |
| AC-SH-5 | Windows with Git for Windows installed | scan runs | `shells.available` contains `bash` with `variant == "git-bash"` | FR-SH-3 |
| AC-SH-6 | Windows | scan runs | `shells.default` follows the resolution of spec Q3 and is never derived from `COMSPEC` | FR-SH-2 |

## AC-TOOL: Installed tool detection

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-TOOL-1 | A new tool is added to the catalog data only (no code change) | scan runs with a fake executable for it on PATH | the tool appears in `tools[]` with `status == "found"` | FR-TOOL-1 |
| AC-TOOL-2 | Every catalog tool absent from a fixture PATH | scan runs | every catalog tool appears in `tools[]` with `status == "not-found"` and `matches == []`; exit code is not 3 | FR-TOOL-2, FR-TOOL-8 |
| AC-TOOL-3 | Windows fixture with `foo.cmd` on PATH and `.CMD` in `PATHEXT` | scan runs with `foo` in catalog | `foo` is found | FR-TOOL-3 |
| AC-TOOL-4 | Fake `node` in two PATH directories, A before B | scan runs | `matches` has 2 entries in PATH order; A is `active: true`, B is `active: false` | FR-TOOL-4 |
| AC-TOOL-5 | `node` on PATH is a symlink to another location | scan runs | `matches[0].path` is the symlink, `matches[0].realPath` is the target | FR-TOOL-5 |
| AC-TOOL-6 | `python` resolves to a pyenv shim directory | scan runs | `matches[0].shim == "pyenv"` | FR-TOOL-6 |
| AC-TOOL-7 | Windows with only the WindowsApps `python.exe` alias present | scan runs | `python.status == "stub"`, the stub was **not** executed (verified by process monitoring or by a fixture stub that writes a marker file when run), and `tool-stub-only` fails | FR-TOOL-7, FR-DIAG-3 |

## AC-VER: Version discovery

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-VER-1 | Fake `git` printing `git version 2.47.1.windows.1` | scan runs | `version == "2.47.1"`, `versionRaw` contains `2.47.1` | FR-VER-6, FR-VER-7 |
| AC-VER-2 | Fake `node` printing `v22.11.0` | scan runs | `version == "22.11.0"` | FR-VER-7 |
| AC-VER-3 | Fake `java` printing `java version "1.8.0_392"` | scan runs | `versionScheme == "nonstandard"`, `version` is non-null | FR-VER-7 |
| AC-VER-4 | Fake tool printing `hello` (no version) | scan runs | `status == "found-version-unknown"`, `probe.output` contains `hello` | FR-TOOL-8, FR-VER-6 |
| AC-VER-5 | Fake tool that sleeps 60 s | scan runs with `--probe-timeout 1` | `status == "timeout"`; scan finishes in under 5 s; no orphaned process remains afterwards | FR-VER-3 |
| AC-VER-6 | Fake tool that waits for stdin | scan runs | tool does not hang the scan; result is `found-version-unknown`, `error`, or `timeout` within the timeout | FR-VER-5 |
| AC-VER-7 | Fake tool exiting with code 1 | scan runs | `status == "error"`, `probe.exitCode == 1` | FR-TOOL-8 |
| AC-VER-8 | User's shell defines an alias/function named `git` that prints a different version | scan runs | reported version comes from the executable, not the alias | FR-VER-2 |
| AC-VER-9 | Tool shadowed at two locations | scan runs without `--probe-all` / with `--probe-all` | only the active match is executed / both are executed and each match reports its own version | FR-VER-8 |
| AC-VER-10 | Fixture tool that records each argument list it is called with | scan runs | the only invocation recorded is the catalog's probe command | FR-VER-1 |

## AC-DIAG: Environment diagnostics

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-DIAG-1 | Every check in spec FR-DIAG-3 | scan runs | each check `id` appears exactly once in `diagnostics[]` with valid `severity` and `status` | FR-DIAG-1, FR-DIAG-3 |
| AC-DIAG-2 | macOS or Linux | scan runs | Windows-only checks (`path-length`, `git-line-endings`, `windows-long-paths`) have `status == "skipped"` with a reason | FR-DIAG-2 |
| AC-DIAG-3 | A check implementation forced to throw (test hook) | scan runs | that check reports `fail` / `warn`, all other checks still run, exit code is not 3 | FR-DIAG-2, NFR-ROB-1 |
| AC-DIAG-4 | PATH contains a non-existent directory | scan runs | `path-missing-dirs` fails and `evidence` lists that directory | FR-DIAG-3 |
| AC-DIAG-5 | PATH contains `/usr/bin` twice (or `C:\Tools` and `c:\tools\`) | scan runs | `path-duplicates` fails | FR-DIAG-3 |
| AC-DIAG-6 | Shadowed `node` where both copies report the same version | scan runs | `tool-shadowed` does not fail for `node` | FR-DIAG-3 |
| AC-DIAG-7 | Shadowed `node` with different versions | scan runs | `tool-shadowed` fails and `evidence` lists both paths and versions | FR-DIAG-3 |
| AC-DIAG-8 | Global git config without `user.email` (isolated via `GIT_CONFIG_GLOBAL` fixture) | scan runs | `git-identity` fails with severity `warn` | FR-DIAG-3 |
| AC-DIAG-9 | `HTTPS_PROXY=http://alice:s3cret@proxy.corp:8080` | scan runs | `proxy-env` reports `HTTPS_PROXY` present; the strings `alice`, `s3cret`, and `proxy.corp` appear nowhere in stdout, stderr, or the report | FR-DIAG-3, NFR-PRIV-1 |
| AC-DIAG-10 | Snapshot of the filesystem, global git config, and (Windows) registry before the scan | scan runs | the snapshot is unchanged afterwards | FR-DIAG-4, NFR-PRIV-4 |
| AC-DIAG-11 | Any failing diagnostic with a `remediation` | scan runs | the remediation is only displayed; no remediation command was executed | FR-DIAG-1 |

## AC-JSON: JSON report and CLI contract

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-JSON-1 | Any machine | `devex doctor --json` | stdout parses as one JSON object, is UTF-8 without BOM, and ends with a newline; nothing else is on stdout | FR-JSON-1, §4 |
| AC-JSON-2 | Any machine, including every fixture in this document | scan runs with `--json` | the report validates against `report.schema.json` | FR-JSON-3 |
| AC-JSON-3 | Same machine state | two scans run back to back | reports are identical after removing `generatedAt`, `durationMs`, and `probe.durationMs` | FR-JSON-6 |
| AC-JSON-4 | Any report | inspect it | every field the schema marks required is present (possibly `null`); all keys are camelCase; `generatedAt` is RFC 3339 UTC | FR-JSON-4, FR-JSON-5 |
| AC-JSON-5 | `devex doctor --output report.json` | runs | `report.json` contains the same report as `--json` would print; human summary is on stdout | §4 |
| AC-JSON-6 | Diagnostics with 0 errors and 1 warn failure | scan runs / scan runs with `--strict` | `summary.status == "warn"`, exit 0 / exit 1 | FR-JSON-8, §4 exit codes |
| AC-JSON-7 | One `error`-severity failure | scan runs | `summary.status == "error"`, exit 1 | FR-JSON-8 |
| AC-JSON-8 | Invalid flag | `devex doctor --bogus` | exit 2, usage message on stderr, nothing on stdout | §4 exit codes |
| AC-JSON-9 | A detector forced to crash (test hook) | scan runs with `--json` | exit 3, stdout still has a schema-valid report, `scanErrors` names the component | FR-JSON-9 |
| AC-JSON-10 | `generator.version` and `schemaVersion` | inspect report | both are valid SemVer strings | FR-JSON-2 |

## AC-PRIV / AC-NFR: Cross-cutting

| ID | Given | When | Then | Covers |
|----|-------|------|------|--------|
| AC-PRIV-1 | Env var `DEVEX_TEST_SECRET=canary-7f3a` set | scan runs | `canary-7f3a` appears nowhere in stdout, stderr, or the report | NFR-PRIV-1 |
| AC-PRIV-2 | `--redact` | scan runs | the home directory path and username appear nowhere in the report or human output; `redacted == true` | NFR-PRIV-2 |
| AC-PRIV-3 | Network disabled at the OS/sandbox level | scan runs | scan completes with the same results as with network enabled (aside from Q6-dependent checks) and no outbound connection attempts are observed | NFR-PRIV-3 |
| AC-PRIV-4 | Standard (non-admin) user | scan runs | no elevation prompt; exit code not 3 | NFR-PRIV-5 |
| AC-NFR-1 | Reference machine per supported OS with ≥ 20 catalog tools installed | 20 scans run | p95 duration ≤ 5 s | NFR-PERF-1 |
| AC-NFR-2 | stdout redirected to a file, or `NO_COLOR=1` | scan runs (human mode) | output has no ANSI escape sequences | NFR-OUT-1 |

## Exit criteria for Phase 0

1. All open questions in spec §9 are resolved or explicitly deferred, with decisions recorded in `spec.md`.
2. Every criterion above passes in CI on each OS in the supported matrix (criteria needing special hardware, such as AC-OS-6 Rosetta, may be verified manually and recorded in the PR).
3. `report.schema.json` is committed and referenced from the README.
