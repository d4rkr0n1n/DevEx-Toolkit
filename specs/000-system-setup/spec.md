# 000 System Setup: Spec

| Field   | Value                                   |
|---------|-----------------------------------------|
| Phase   | 0                                        |
| Status  | Draft — open questions in §9 must be resolved before `plan.md` |
| Date    | 2026-11-17                               |
| Related | [`acceptance.md`](acceptance.md), [`../constitution.md`](../constitution.md) |

## 1. Purpose

Phase 0 gives DevEx CLI an accurate, read-only picture of the machine it runs on. Every later phase (dashboard, frontend/backend/devops/platform tools) depends on knowing what OS, shell, and developer tools are present and whether the environment is healthy. Phase 0 produces that picture once, in a form both people and programs can consume.

## 2. Scope

### In scope

1. OS detection
2. Shell detection
3. Detection of installed developer tools
4. Version discovery for detected tools
5. Environment diagnostics (health checks with remediation hints)
6. A human-readable summary and a machine-readable JSON report

### Out of scope (non-goals)

- Installing, upgrading, or uninstalling anything.
- Modifying configuration, environment variables, PATH, registry, or dotfiles.
- Any network access, including update checks and telemetry.
- Checking whether a tool's version is the *latest*; Phase 0 reports what is installed, not what is available.
- Project-level analysis (reading `package.json`, `pyproject.toml`, etc.). Phase 0 describes the machine, not a repository.
- Fixing diagnostics automatically.

## 3. Definitions

| Term | Meaning |
|------|---------|
| **Scan** | One execution of Phase 0 detection end to end. |
| **Tool** | An executable listed in the tool catalog (§5.3). |
| **Catalog** | Declarative data describing which tools to look for and how to probe their versions. |
| **Probe** | Running a catalog-defined command (e.g. `git --version`) to obtain a version. |
| **Shim** | A wrapper executable from a version manager (nvm, pyenv, asdf, mise, volta, rbenv, etc.) that forwards to a real binary. |
| **Shadowed** | A tool found at more than one PATH location; only the first is used when invoked. |
| **Check** | A single diagnostic rule producing a result with a severity. |

## 4. User-facing behaviour

The command name is **provisional** (see Q1). This spec uses `devex doctor`.

| Invocation | Behaviour |
|------------|-----------|
| `devex doctor` | Runs a scan and prints a human-readable summary to stdout. |
| `devex doctor --json` | Prints only the JSON report to stdout. Nothing else is written to stdout. |
| `devex doctor --output <path>` | Writes the JSON report to `<path>`; human summary still goes to stdout unless `--json` is also given. |
| `devex doctor --strict` | Treats `warn` diagnostics as failures for exit-code purposes. |
| `devex doctor --redact` | Replaces the user's home directory and username in all paths and values (see §6). |

Logs, progress output, and warnings about the scan itself go to **stderr**, never stdout.

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Scan completed; no `error` diagnostics (and no `warn` if `--strict`). |
| 1 | Scan completed; at least one `error` diagnostic (or `warn` with `--strict`). |
| 2 | Usage error (invalid flags or arguments). |
| 3 | Scan could not complete (internal failure). A partial report is still emitted if possible. |

A tool being absent is **not** by itself an error; it only affects the exit code if a diagnostic check raises it.

## 5. Functional requirements

Requirement IDs are referenced by `acceptance.md`.

### 5.1 OS detection

- **FR-OS-1** Report OS family as one of `windows`, `macos`, `linux`, `other`.
- **FR-OS-2** Report OS version and build:
  - Windows: product name (e.g. Windows 11), display version (e.g. 24H2), and build number.
  - macOS: product version (e.g. 15.1) and build (e.g. 24B83).
  - Linux: distribution `id`, `name`, and `versionId` from `/etc/os-release` (falling back to `/usr/lib/os-release`); `null` fields if neither exists.
- **FR-OS-3** Report kernel version where available.
- **FR-OS-4** Report CPU architecture normalized to `x64`, `arm64`, `x86`, `arm`, or `other`, plus the raw value.
- **FR-OS-5** Report whether the CLI process runs under emulation (Rosetta 2 on macOS, x64 emulation on Windows on Arm) when determinable; otherwise `null`.
- **FR-OS-6** Report environment context flags: `wsl` (with WSL version 1/2 if determinable), `container` (Docker/Podman/other, if determinable), and `ci` (when a well-known CI environment variable is set, e.g. `CI`, `GITHUB_ACTIONS`).
- **FR-OS-7** Report total memory and logical CPU count. (Disk space: see Q7.)

### 5.2 Shell detection

Three different questions are answered separately, because they often have different answers:

- **FR-SH-1 Current shell** — the shell that launched the CLI, found by inspecting the parent process chain. Report name, path, and version if probeable. If the parent is not a recognised shell (e.g. an IDE task runner), report `null` and record why.
- **FR-SH-2 Default shell** — the user's configured login/default shell:
  - Unix: the login shell from the user database, falling back to `$SHELL`.
  - Windows: see Q3; until resolved, report Windows Terminal's default profile if determinable, else `null`.
- **FR-SH-3 Available shells** — every recognised shell found on the machine, each with name, path(s), and version. Recognised set at minimum: `bash`, `zsh`, `fish`, `sh`, `dash`, `pwsh` (PowerShell 7+), `powershell` (Windows PowerShell 5.1), `cmd`, `nu`. Git Bash and MSYS2 bash on Windows are reported as `bash` with a `variant` field.
- **FR-SH-4** Each shell result carries a `detectionMethod` (e.g. `parent-process`, `env-var`, `user-database`, `path-lookup`) so consumers can judge reliability.

### 5.3 Installed developer tools

- **FR-TOOL-1** Tools to detect are defined in a declarative catalog, separate from detection logic. Adding a tool must not require changing detection code. Each catalog entry defines: `id`, display name, category, executable name(s) per OS, version probe command, version-parse rule, and optional OS restriction.
- **FR-TOOL-2** The Phase 0 catalog covers at minimum the following (final list: Q4):

  | Category | Tools |
  |----------|-------|
  | Version control | git, gh |
  | Runtimes / languages | node, deno, bun, python, java, go, rustc, dotnet, ruby, php |
  | Package managers | npm, pnpm, yarn, pip, uv, cargo, gem, composer, brew, winget, scoop, choco, apt |
  | Version managers | nvm, fnm, volta, pyenv, asdf, mise, rbenv, sdkman |
  | Containers / orchestration | docker, podman, kubectl, helm, kind, minikube |
  | Cloud CLIs | aws, az, gcloud, terraform |
  | Build tools | make, cmake, gradle, mvn |
  | Editors | code (VS Code), cursor |

- **FR-TOOL-3** A tool is located by resolving its executable names against PATH using the platform's resolution rules (on Windows, honouring `PATHEXT`).
- **FR-TOOL-4** Report **every** PATH match in order, not just the first. The first is marked `active`; the others are marked `shadowed`.
- **FR-TOOL-5** For each match, report the path as found and the resolved real path after following symlinks.
- **FR-TOOL-6** Detect when a match is a version-manager shim and report the manager (`nvm`, `pyenv`, `volta`, etc.). Resolving the shim's underlying target is best-effort.
- **FR-TOOL-7** Detect Windows App Execution Alias stubs (e.g. `python.exe` in `%LOCALAPPDATA%\Microsoft\WindowsApps` that opens the Microsoft Store). Report them as `status: "stub"` and do **not** execute them.
- **FR-TOOL-8** Each tool result has exactly one `status`:

  | Status | Meaning |
  |--------|---------|
  | `found` | Located and version parsed. |
  | `found-version-unknown` | Located; probe ran but output could not be parsed. |
  | `stub` | Only a placeholder/alias was found (FR-TOOL-7). |
  | `timeout` | Located; probe exceeded the timeout. |
  | `error` | Located; probe failed (non-zero exit, crash, permission denied). |
  | `not-found` | Not located. |

### 5.4 Version discovery

- **FR-VER-1** Versions are obtained only by running the catalog-defined probe for that tool. No other commands are executed against tools.
- **FR-VER-2** Probes run without a shell interpreter (direct process execution with an argument list) so user shell configuration and aliases cannot alter results.
- **FR-VER-3** Each probe has a timeout (default 5 s, configurable via `--probe-timeout`). On timeout the process tree is terminated.
- **FR-VER-4** Probes run concurrently with a bounded pool (default: logical CPU count, max 8).
- **FR-VER-5** Probe stdin is closed / empty, so a tool waiting for input cannot hang the scan.
- **FR-VER-6** Report, per tool: `version` (normalized string, see FR-VER-7), `versionRaw` (the matched substring), and `probeOutput` (first 1 KB of combined stdout/stderr, trimmed). `probeOutput` is omitted when `--redact` is set unless it contains no home path or username after redaction.
- **FR-VER-7** Normalization: extract the first `MAJOR.MINOR[.PATCH][-PRERELEASE]` match per the catalog's parse rule. Leading `v` is stripped. Versions that don't fit (e.g. dates, Java's `1.8.0_392`) keep their raw form in `version` and set `versionScheme: "nonstandard"`.
- **FR-VER-8** When a tool has multiple PATH matches (FR-TOOL-4), only the `active` match is probed by default. `--probe-all` probes every match.

### 5.5 Environment diagnostics

- **FR-DIAG-1** Diagnostics are implemented as independent checks. Each produces: `id` (stable, kebab-case), `title`, `severity` (`info` | `warn` | `error`), `status` (`pass` | `fail` | `skipped`), `message`, optional `remediation` (text hint only, never executed), and optional `evidence` (structured data).
- **FR-DIAG-2** A check that cannot run (e.g. not applicable to the OS) reports `status: "skipped"` with a reason. A check that throws reports `status: "fail"`, `severity: "warn"` and does not abort the scan.
- **FR-DIAG-3** Phase 0 required checks:

  | ID | Condition flagged | Default severity |
  |----|-------------------|------------------|
  | `path-missing-dirs` | PATH entries that do not exist | warn |
  | `path-duplicates` | Same directory appears more than once in PATH (after normalization) | info |
  | `path-length` | Windows: PATH length near or above platform limit | warn |
  | `tool-shadowed` | A tool has multiple PATH matches with different versions | warn |
  | `tool-stub-only` | Only an App Execution Alias stub exists for a tool | warn |
  | `git-identity` | `git` found but `user.name` or `user.email` unset globally | warn |
  | `git-line-endings` | Windows: `core.autocrlf` unset | info |
  | `windows-long-paths` | Windows: long path support disabled | warn |
  | `home-dir` | `HOME` (Unix) or `USERPROFILE` (Windows) unset or not a directory | error |
  | `locale-utf8` | Locale / console code page is not UTF-8 | info |
  | `proxy-env` | Proxy variables set (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, lowercase variants); report names and redacted values only | info |
  | `docker-daemon` | `docker` found but daemon unreachable — see Q6 | warn |

- **FR-DIAG-4** Diagnostics read configuration only through read-only means (`git config --global --get`, registry reads, file reads). They never write.

### 5.6 JSON report

- **FR-JSON-1** The report is a single UTF-8 JSON object, no BOM, terminated by a newline.
- **FR-JSON-2** The report contains a `schemaVersion` following SemVer. Adding optional fields is a minor bump; removing or renaming fields, or changing a field's type or meaning, is a major bump.
- **FR-JSON-3** A JSON Schema (draft 2020-12) for the report is a deliverable of Phase 0, stored at `specs/000-system-setup/report.schema.json`, and every emitted report validates against it.
- **FR-JSON-4** Field names are camelCase. Absent/unknown values are `null`, not omitted, for every field defined as required by the schema.
- **FR-JSON-5** Timestamps are RFC 3339 in UTC. Durations are integer milliseconds.
- **FR-JSON-6** Output is deterministic for a given machine state: arrays are sorted (tools by `id`, shells by `name`, diagnostics by `id`, PATH matches in PATH order). The only fields expected to differ between identical runs are `generatedAt`, `durationMs`, and per-probe `durationMs`.
- **FR-JSON-7** Top-level structure:

```json
{
  "schemaVersion": "1.0.0",
  "generator": { "name": "devex-cli", "version": "0.1.0" },
  "generatedAt": "2026-11-17T10:42:03Z",
  "durationMs": 1840,
  "redacted": false,
  "host": {
    "os": {
      "family": "windows",
      "name": "Windows 11 Home Single Language",
      "version": "24H2",
      "build": "26300",
      "kernel": "10.0.26300",
      "distro": null
    },
    "arch": { "normalized": "x64", "raw": "AMD64" },
    "emulated": false,
    "context": { "wsl": null, "container": null, "ci": null },
    "cpuCount": 16,
    "memoryBytes": 34359738368
  },
  "shells": {
    "current": { "name": "pwsh", "path": "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "version": "7.5.4", "variant": null, "detectionMethod": "parent-process" },
    "default": null,
    "available": [
      { "name": "bash", "path": "C:\\Program Files\\Git\\bin\\bash.exe", "version": "5.2.37", "variant": "git-bash", "detectionMethod": "path-lookup" }
    ]
  },
  "tools": [
    {
      "id": "python",
      "name": "Python",
      "category": "runtime",
      "status": "found",
      "version": "3.13.1",
      "versionRaw": "Python 3.13.1",
      "versionScheme": "semver",
      "probe": { "command": ["python", "--version"], "exitCode": 0, "durationMs": 61, "output": "Python 3.13.1" },
      "matches": [
        { "path": "C:\\Users\\me\\.pyenv\\shims\\python.bat", "realPath": "C:\\Users\\me\\.pyenv\\shims\\python.bat", "active": true, "shim": "pyenv", "stub": false },
        { "path": "C:\\Users\\me\\AppData\\Local\\Microsoft\\WindowsApps\\python.exe", "realPath": null, "active": false, "shim": null, "stub": true }
      ]
    }
  ],
  "diagnostics": [
    {
      "id": "git-identity",
      "title": "Git identity configured",
      "severity": "warn",
      "status": "fail",
      "message": "git user.email is not set globally.",
      "remediation": "Run: git config --global user.email \"you@example.com\"",
      "evidence": { "userName": true, "userEmail": false }
    }
  ],
  "summary": {
    "status": "warn",
    "tools": { "found": 18, "notFound": 31, "other": 2 },
    "diagnostics": { "pass": 9, "info": 1, "warn": 2, "error": 0, "skipped": 1 }
  },
  "scanErrors": []
}
```

- **FR-JSON-8** `summary.status` is `error` if any diagnostic is `fail` with severity `error`; else `warn` if any `fail` with severity `warn`; else `ok`.
- **FR-JSON-9** `scanErrors` lists failures of the scan itself (e.g. a detector crashed), each with `component` and `message`. A scan with entries in `scanErrors` still emits all sections it could complete.

## 6. Privacy and safety

- **NFR-PRIV-1** Environment variable **values** are never included in the report, except: PATH entries (as a list of directories), and specific named variables the spec allows (`SHELL`, `TERM`, `LANG`/`LC_*`). Proxy variables are reported with credentials and host stripped (e.g. `http://***@***:8080` → present + scheme + port only).
- **NFR-PRIV-2** With `--redact`, the user's home directory is replaced with `~` (or `%USERPROFILE%` on Windows) and the username with `<user>` everywhere in the report, including probe output and the human summary.
- **NFR-PRIV-3** The scan performs no network I/O. Local IPC (e.g. Docker socket/named pipe) is allowed only if Q6 resolves that way.
- **NFR-PRIV-4** The scan writes nothing to disk except the `--output` file.
- **NFR-PRIV-5** The scan requires no elevated privileges and must not prompt for them.

## 7. Non-functional requirements

- **NFR-PERF-1** A full scan completes in ≤ 5 s at p95 on a supported machine with the default catalog and up to 30 tools installed, with warm OS caches. Each probe is bounded by its timeout, so worst case is bounded by `ceil(tools / pool) × timeout` plus detection overhead.
- **NFR-PORT-1** Supported platforms (pending Q2): Windows 10 22H2+ and Windows 11 (x64, arm64); macOS 13+ (arm64, x64); Ubuntu 22.04+, Debian 12+, Fedora 40+ (x64, arm64); WSL 2 running one of those distros.
- **NFR-ROB-1** No single detector, probe, or check failure aborts the scan (§5.5 FR-DIAG-2, §5.6 FR-JSON-9).
- **NFR-OUT-1** Human output honours `NO_COLOR` and disables colour when stdout is not a TTY.

## 8. Implementation constraints for later phases

Phase 0 exposes its results as an internal API (scan result object) that other phases reuse; the JSON report is a serialization of that object, not a separate code path. Later phases must not re-run detection independently.

## 9. Open questions and ambiguities

Each has a proposed default that `plan.md` will adopt unless overridden.

| # | Question | Why it matters | Proposed default |
|---|----------|----------------|------------------|
| Q1 | Command name: `devex doctor`, `devex system scan`, `devex env`, or `devex init`? | User-facing contract; hard to change later. | `devex doctor` (familiar from `flutter doctor`, `brew doctor`). |
| Q2 | Exact supported OS/version/arch matrix, and is WSL 1 supported? | Determines CI matrix and test fixtures. | Matrix in NFR-PORT-1; WSL 1 detected but best-effort. |
| Q3 | What is "default shell" on Windows? There is no OS-level equivalent of a login shell. Options: Windows Terminal default profile, `COMSPEC` (always cmd), VS Code's configured terminal, or omit. | FR-SH-2 is otherwise undefined on Windows. | Windows Terminal default profile if readable, else `null`. Never use `COMSPEC`. |
| Q4 | Final Phase 0 tool catalog. Should it be user-extensible (config file) in Phase 0? | Scope and test effort scale with catalog size. | Catalog in FR-TOOL-2; user extension deferred to a later phase, but the catalog format must not preclude it. |
| Q5 | Implementation language/runtime is not chosen, and `constitution.md` is empty. | Affects distribution (single binary vs runtime dependency), and whether detecting e.g. `node` is circular. | Decide in `constitution.md` before `plan.md`. Spec is language-agnostic. |
| Q6 | Is querying the Docker daemon (local socket / named pipe) allowed under "no network"? | `docker-daemon` check needs it; a hung daemon could slow the scan. | Allowed as local IPC via `docker version` probe with the standard timeout. |
| Q7 | Include free disk space? On which volume(s)? | Useful, but "which volume" is ambiguous on multi-drive machines. | Report free space for the home directory's volume and the temp directory's volume only. |
| Q8 | Should missing *commonly expected* tools (e.g. no `git`) be a diagnostic, and at what severity? | Affects exit code and `--strict` in CI. | Only `git` missing raises a diagnostic (`git-missing`, warn). Other absences are informational via `tools[]`. |
| Q9 | Is the human-readable output format part of the stable contract? | Users may scrape it. | No. Only the JSON report and exit codes are stable; docs say to use `--json` for automation. |
| Q10 | Should `--probe-all` (FR-VER-8) be in Phase 0 at all? | Doubles probe count for shadowed tools. | Yes, opt-in only. |
| Q11 | How are version-manager-managed but not-currently-active versions handled (e.g. 3 Node versions installed via nvm, one active)? | Users may expect all installed versions listed. | Phase 0 reports only what PATH resolves to. Enumerating manager inventories is deferred. |
| Q12 | Should the JSON include a per-machine identifier? | Useful for dashboards (Phase 2) but a privacy concern. | No identifier in Phase 0. |
| Q13 | Where should the JSON Schema be published for external consumers (repo path only, or a stable URL in `$schema`)? | Third-party tooling validation. | Repo path only in Phase 0; `$schema` URL added once a docs site exists. |

## 10. Deliverables

1. `devex doctor` command meeting §4–§7.
2. Tool catalog data file (format chosen in `plan.md`).
3. `report.schema.json` (FR-JSON-3).
4. Tests and fixtures meeting [`acceptance.md`](acceptance.md).
5. README section documenting usage, exit codes, and JSON stability policy.
