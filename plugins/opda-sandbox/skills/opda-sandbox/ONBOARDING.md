# Onboarding to the OPDA / PDTF sandbox

You need two things before the scripts work:

1. An **mTLS transport certificate + private key**, signed by the sandbox CA.
2. Your **client_id** — the full Relying Party URL from the Raidiam directory.

---

## 1. Join the sandbox

Request access at
<https://openpropdata.org.uk/smart-property-data-trust-framework/> ("Join the
sandbox"). OPDA / Raidiam create your organisation in the directory and an
Application with a role (e.g. PIC) using FAPI defaults (`PS256`,
`tls_client_auth`). It is free and open to everyone.

## 2. Get your certificates

Generate a private key + CSR and submit the CSR to Raidiam to sign. They issue a
**transport cert** (used for mTLS on every call) and one or more **signing
certs**. Raidiam will confirm the exact CSR subject requirements — follow theirs,
as they vary by role.

A typical transport CSR (confirm the subject with Raidiam first):

```bash
openssl req -new -newkey rsa:2048 -nodes \
  -keyout transport.key -out transport.csr \
  -subj "/CN=<your-app-uuid>/O=<your-org-name>"
```

You end up with `transport.pem` (the signed cert) and `transport.key` (your
private key — keep it secret).

## 3. Place your certs

```bash
mkdir -p ~/.opda-sandbox
mv transport.pem transport.key ~/.opda-sandbox/
chmod 600 ~/.opda-sandbox/transport.key
```

## 4. Create your config

```bash
cp config.example.env ~/.opda-sandbox/config.env
```

Edit `~/.opda-sandbox/config.env`:

- **`CLIENT_ID`** — the **full RP URL** from your directory Application, e.g.
  `https://rp.directory.pdtf.raidiam.io/openid_relying_party/<your-app-uuid>`.
  ⚠️ Not the bare UUID — that returns `401 invalid_client`.
- **`OPDA_CERT_DIR` / `TRANSPORT_CERT` / `TRANSPORT_KEY`** — point at your files.

> Why `~/.opda-sandbox/` and not inside the skill? When installed as a plugin,
> the skill folder is replaced on every update — config kept there would be lost.
> `~/.opda-sandbox/` is stable and sits with your certs.

## 5. Verify

```bash
bash scripts/check-setup.sh
```

All `[ok]` plus "you're connected!" means you're ready. Then explore:

```bash
bash scripts/directory.sh endpoints
```

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `401 invalid_client` | `client_id` is the bare UUID — use the full RP URL. |
| `no config found` | Create `~/.opda-sandbox/config.env` from `config.example.env`. |
| `no token` / TLS errors | Wrong cert/key path, or your cert isn't active in the directory yet. |
| `MISSING transport cert/key` | Paths in `config.env` don't match where you put the files. |
| `403 IncompleteSignatureException` | **Not** a signature/server bug — an AWS API Gateway catch-all. Almost always the **wrong URL shape** or **wrong scope** for that endpoint. See "Government-data endpoints" in `SKILL.md` and use `gov-data.sh`. |
| `401 missing_authorization` *with* a valid token | Right token, **wrong scope/aud** for that endpoint (e.g. OPDA government-data wants scope `land-registry`, not `government-data`). |
| Endpoint needs `private_key_jwt` | Set `SIGNING_KEY`/`SIGNING_KID` in your config and add a SIGNING cert to your app. Your app must be registered with `token_endpoint_auth_method = private_key_jwt`. If it's a **federation-managed** app you can't change it after the fact (and org-admins can't unlock it) — just **create a new Application**, pick `private_key_jwt` at the final step, and give it its own signing + transport certs. |
| Stuck getting credentials | OPDA / Raidiam support and the Friday tech drop-in can help. |

**Windows users:** run the scripts from **WSL** or **Git Bash** (they need
`bash`, `curl`, and `python3`).
