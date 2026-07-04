# Security Policy

This repository ships a persona canon, process skills, installer scripts, and an
opinionated permission-and-hooks model for AI coding assistants. It runs no
service and stores no user data. Its security surface is therefore narrow and
specific, and worth stating plainly.

## What the security surface actually is

1. **Accidental disclosure into the repository.** The kit is meant to be forked
   and edited. The risk is a contributor committing a real secret, credential,
   transcript, or employer-internal detail. Defenses: a whitelist-style
   `.gitignore`, a write-time secret-pattern scan hook, and a protected-file
   guard. These are backstops, not permission to be careless — see
   [`CONTRIBUTING.md`](./CONTRIBUTING.md) and [`docs/hardening.md`](./docs/hardening.md).

2. **The permission model you install.** `claude-code/.claude/settings.example.json`
   defines what an assistant may do unattended. Weakening it (adding destructive
   or outbound commands to the allowlist) is a security decision. The shipped
   lists are deliberately conservative; review any change to them as you would a
   change to a firewall rule. Rationale in [`docs/hardening.md`](./docs/hardening.md).

3. **The installer scripts.** They symlink or copy files into `~/.claude`,
   `$CODEX_HOME`, and a Copilot workspace. Read them before running, as you should
   with any setup script. They make no network calls and require no elevated
   privileges.

## Reporting a vulnerability

If you find a vulnerability — a secret-scan or protected-file guard that can be
bypassed, an installer that writes outside its intended targets, a permission
default that is unsafe as shipped, or a supply-chain concern — report it
privately. Do **not** open a public issue for a security problem.

- Use GitHub's **private vulnerability reporting** ("Report a vulnerability" under
  the repository's **Security** tab). This opens a private advisory visible only
  to maintainers.

Please include what you found, how to reproduce it, and the impact you see. We
aim to acknowledge a report within a few days and to agree on a disclosure
timeline before any public discussion.

## Scope

**In scope:** the hooks, the permission defaults, the installer scripts, the
sync/drift tooling, and anything in this repository that could cause secret
leakage or unintended local file changes.

**Out of scope:** vulnerabilities in the underlying AI assistants (Claude Code,
Codex, Copilot) or their host platforms — report those to their respective
vendors. General "the assistant did something I didn't like" behavior that isn't
a bypass of a guard shipped here.

## If you've already leaked a secret

The scanners reduce the odds; they don't guarantee it. If a real secret reached a
commit: rotate the credential first (assume it is compromised the moment it
touched history), then scrub it from history. Rotation is the fix; history
rewriting is cleanup.
