---
name: opda-sandbox
description: Onboard to the OPDA / PDTF (Property Data Trust Framework) sandbox and pull its APIs with your own credentials. Walks a new participant through adding their mTLS cert + full-URL client_id, verifies the setup, then discovers and consumes any provider's sandbox endpoint with provenance. Use when someone needs to connect to the OPDA / PDTF sandbox, add sandbox credentials, fix a 401 invalid_client, or query the OPDA / Raidiam directory APIs.
---

# OPDA / PDTF sandbox — connect & pull APIs

Onboard any participant to the OPDA / Property Data Trust Framework sandbox
(Raidiam directory) and consume its APIs with your **own** credentials.
Portable `bash` + `curl` + `python3` — runs on macOS/Linux directly, and on
Windows via WSL or Git Bash.

## First time? Read [ONBOARDING.md](ONBOARDING.md)

It walks you through getting sandbox credentials, placing your certs, and
filling in config. Come back here once `check-setup.sh` is green.

## Quick start (once you have credentials)

1. Put your mTLS **transport cert + key** in `~/.opda-sandbox/`.
2. Create your config from the template (kept outside the skill so it survives
   plugin updates):
   ```bash
   mkdir -p ~/.opda-sandbox
   cp config.example.env ~/.opda-sandbox/config.env   # then edit it
   ```
3. Verify you're connected:
   ```bash
   bash scripts/check-setup.sh
   ```
4. Discover and consume:
   ```bash
   bash scripts/directory.sh             # onboarded organisations
   bash scripts/directory.sh endpoints   # every live published endpoint
   bash scripts/consume.sh <scope> GET <url>
   ```

> Using Claude Code? Just ask: *"help me onboard to the OPDA sandbox"* — Claude
> reads ONBOARDING.md, helps you fill the config, runs `check-setup.sh`, and reads
> any errors back to fix them (e.g. it catches a bare-UUID client_id for you).

## The one gotcha that costs everyone hours

`client_id` MUST be the **full RP URL**
(`https://rp.directory.pdtf.raidiam.io/openid_relying_party/<your-app-uuid>`),
never the bare UUID. The bare UUID returns `401 invalid_client`. `check-setup.sh`
catches this for you.

## Scripts

| Script | Does |
|---|---|
| `check-setup.sh` | Verify certs + config, mint a test token. **Run this first.** |
| `token.sh [scope]` | Print a scoped access token. |
| `directory.sh [orgId\|endpoints]` | List orgs / sweep live endpoints / one org's endpoints. |
| `consume.sh <scope> <METHOD> <url> [body]` | Call any endpoint; surface JWS + provenance / verifiedClaims. |

## Security

- Your **key files and `config.env` live in `~/.opda-sandbox/`** and never leave your machine — never commit or email them.
- This skill ships `config.example.env` (placeholders) only. `.gitignore` excludes the rest.
