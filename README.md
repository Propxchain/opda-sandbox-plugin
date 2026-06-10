# OPDA / PDTF Sandbox — Claude Code plugin

A Claude Code plugin that helps you **onboard to the [OPDA](https://openpropdata.org.uk)
/ Property Data Trust Framework (PDTF) sandbox** and pull its APIs with your own
credentials — mTLS auth, Raidiam directory discovery, and provenance-aware consumption.

## Install (Claude Code)

```
/plugin marketplace add Propxchain/opda-sandbox-plugin
/plugin install opda-sandbox@propxchain-opda
```

Then, in any session: *"help me onboard to the OPDA sandbox"* — Claude loads the
skill and walks you through it (placing certs, filling config, verifying, and
making your first API pull).

## What you need first

Sandbox credentials from OPDA / Raidiam — an mTLS transport cert + key, and your
full-URL `client_id`. The skill's `ONBOARDING.md` walks you through getting them
and placing them in `~/.opda-sandbox/`.

## Not a Claude Code user?

The scripts run standalone with `bash` + `curl` + `python3` — see
[`plugins/opda-sandbox/skills/opda-sandbox/ONBOARDING.md`](plugins/opda-sandbox/skills/opda-sandbox/ONBOARDING.md).
(Windows: run from WSL or Git Bash.)

## Security

Your credentials live in `~/.opda-sandbox/` on your own machine and never leave it.
This repo ships **placeholders only** — no keys, no `client_id`.

## Layout

```
.claude-plugin/marketplace.json          # this marketplace's catalogue
plugins/opda-sandbox/
├── .claude-plugin/plugin.json           # plugin manifest
└── skills/opda-sandbox/                 # the skill Claude loads
    ├── SKILL.md  ONBOARDING.md  config.example.env
    └── scripts/  check-setup.sh · directory.sh · consume.sh · token.sh · _common.sh · lib_fmt.py
```
