# Secrets Management — Zion Docker Services

**Status:** ⚠️ MIGRATION IN PROGRESS
**Last Updated:** 2026-03-20
**Severity:** CRITICAL — Real API credentials exposed in git history

---

## Current State (Legacy)

❌ **Problem:** Environment files contain real API credentials committed to git:
- `API_PDF_KIT_TOKEN` — development & production tokens
- `SENTRY_DSN` — real authentication token (with project ID & client key)
- `PAGARME_MERCHANT` / `PAGARME_ACCOUNT` — production payment processor credentials
- `GOOGLE_CLIENT_ID` — OAuth credentials (different per environment)
- `HCAPTCHA_SITE_KEY` — real credential
- `QUESTIONS_ASSETS_BUCKET` — AWS bucket name (production)

**Exposed Since:** Commit c58334b (initial Docker config)
**Locations:**
```
zion/dockerized/{bo-container,front-student,monolito}/env/{local,prod,qa,sandbox}.env
```

**Risk Surface:**
1. **Source Control:** Anyone with repo access (internal/external) can retrieve production credentials
2. **Container Inspection:** `docker inspect` / `docker run -e` exposes credentials as plaintext env vars
3. **Logs:** Application logs may leak env var values
4. **CI/CD:** Secrets visible in build logs, artifact caches

---

## Immediate Actions (Remediation)

### Step 1: Prevent Further Commits ✓ (DONE)

```bash
# Added to .gitignore:
zion/dockerized/**/env/*.env        # Ignore all .env files
!zion/dockerized/**/env/*.env.example  # BUT track .env.example templates
```

✓ Created `.env.example` templates with `CHANGE_ME` placeholders
✓ All current `.env` files are now ignored by git

### Step 2: Rotate All Exposed Credentials (REQUIRED)

**Timeline:** Within 24 hours of merge

**Credentials to rotate:**

| Credential | Service | Priority | Action |
|---|---|---|---|
| `API_PDF_KIT_TOKEN` | PDF Kit (dev & prod) | CRITICAL | Revoke old tokens; generate new ones |
| `SENTRY_DSN` | Sentry (org `4506819083436032`) | CRITICAL | Rotate auth token in project settings |
| `PAGARME_MERCHANT` / `PAGARME_ACCOUNT` | Pagar.me | CRITICAL | Revoke API keys; generate new |
| `GOOGLE_CLIENT_ID` | Google OAuth (2 different IDs) | HIGH | Regenerate OAuth credentials; delete old |
| `HCAPTCHA_SITE_KEY` | hCaptcha | MEDIUM | Regenerate site/secret key pair |
| `AWS bucket` (`estrategia-prod-questoes`) | S3 Access | HIGH | Rotate IAM credentials with S3 access |

**Who rotates:** DevOps team (must coordinate with each service owner)

### Step 3: Scan & Clean Git History (REQUIRED)

Run `gitleaks` to identify all credential patterns in history:

```bash
# Install gitleaks (if not present):
nix shell nixpkgs#gitleaks

# Scan entire history:
gitleaks detect --verbose --report-path gitleaks-report.json

# Review report for confirmed leaks:
cat gitleaks-report.json | jq '.[]' | head -50
```

**Expected findings:**
- API_PDF_KIT_TOKEN pattern in multiple commits
- Pagar.me merchant/account IDs
- hCaptcha site key (same value across files)
- Sentry DSN with auth token
- Google OAuth IDs

**Remediation options:**

#### Option A: `git-filter-repo` (Recommended if no external forks)
```bash
# Create .env file patterns to remove:
cat > /tmp/filter-patterns.txt << 'EOF'
API_PDF_KIT_TOKEN=.*
SENTRY_DSN=https://.*
PAGARME_MERCHANT=.*
PAGARME_ACCOUNT=.*
GOOGLE_CLIENT_ID=.*
HCAPTCHA_SITE_KEY=.*
EOF

# Filter history:
git filter-repo --invert-paths --paths-from-file /tmp/filter-patterns.txt
git push --force-with-lease origin main
```

#### Option B: `git-crypt` + `git-history-rewrite`
See §Future State below.

---

## Future State (Target Architecture)

### Approach: `sops-nix` + `agenix` (Recommended)

**Why:**
- Secrets encrypted at rest in git
- Decryption happens only on host (via NixOS)
- Container gets secrets via volume mount (encrypted until runtime)
- No plaintext env files in repo

**Implementation:**

#### 1. Set up `agenix` (age-based encryption)

```nix
# flake.nix (add agenix input)
{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, agenix, ... }:
}
```

#### 2. Create age keys

```bash
# Generate age identity for host:
mkdir -p ~/.config/agenix
age-keygen -o ~/.config/agenix/host.key

# Extract public key:
cat ~/.config/agenix/host.key | grep "# public key:" | cut -d' ' -f4
# Output: age1xyz...

# For NixOS module: add to secrets.nix
```

#### 3. Encrypt secrets

```bash
# Create encrypted secret (for PDF Kit token, etc.):
nix run agenix -- -e secrets/pdf-kit-token.age
# Opens $EDITOR to input token; encrypts with host.key

# Or batch encrypt from plaintext:
agenix -i ~/.config/agenix/host.key \
  -r age1xyz... \
  -e secrets/pdf-kit-token.age < <(echo "RXWWT3YC84D2MQ7W28WWNTS8GCARM9TG")
```

#### 4. NixOS module to inject into containers

```nix
# modules/zion-secrets.nix
{ config, lib, pkgs, ... }:
with lib;
{
  options.zion.secrets.enable = mkEnableOption "Zion secrets encryption";

  config = mkIf config.zion.secrets.enable {
    age.secrets = {
      pdf-kit-token = {
        file = ../secrets/pdf-kit-token.age;
        owner = "zion";
        group = "zion";
        mode = "0600";
      };
      sentry-dsn = {
        file = ../secrets/sentry-dsn.age;
        owner = "zion";
        group = "zion";
        mode = "0600";
      };
      # ... more secrets
    };

    # Docker service configuration
    virtualisation.docker.extraOptions = "--env-file /run/agenix/sentry-dsn";
  };
}
```

#### 5. Docker Compose integration

```yaml
# docker-compose.zion.yml
services:
  front-student:
    image: ...
    env_file:
      - /run/agenix/pdf-kit-token
      - /run/agenix/sentry-dsn
    # OR:
    environment:
      API_PDF_KIT_TOKEN: ${PDF_KIT_TOKEN}  # injected from host env
      SENTRY_DSN: ${SENTRY_DSN}
```

---

## Transition Plan

### Phase 1 (Current): Prevention
- ✓ Add `.gitignore` patterns
- ✓ Create `.env.example` templates
- [ ] Document in this file (you are here)
- [ ] Rotate exposed credentials (team action)
- [ ] Scan & clean git history (team action)

### Phase 2: sops-nix/agenix Setup
- [ ] Add agenix to flake.nix
- [ ] Generate age keys for host
- [ ] Create secrets directory with encrypted files
- [ ] Update NixOS module for secret injection

### Phase 3: Container Integration
- [ ] Test secret injection in docker-compose
- [ ] Remove plaintext `.env` files from containers
- [ ] Verify Sentry/PDF-Kit/Pagar.me integration works

### Phase 4: Cleanup
- [ ] Remove old .env files from working tree
- [ ] Document per-service credential location
- [ ] Add secret rotation schedule (quarterly)

---

## Local Development Workflow

Once agenix is in place:

### Setup (first time)
```bash
# Generate your local age key:
age-keygen -o ~/.config/agenix/host.key

# Add public key to secrets.nix:
# (share with team for collective encryption)

# Re-encrypt all secrets with new key:
agenix --rekey
```

### Running Services
```bash
# Secrets are automatically injected by NixOS:
zion docker run front-student --env=local

# Environment variables available inside container:
docker exec <container> env | grep API_PDF_KIT
# Output: API_PDF_KIT_TOKEN=<decrypted-value>
```

### Adding a New Secret
```bash
# Create encrypted secret:
nix run agenix -- -e secrets/new-api-key.age

# Add to NixOS module:
# age.secrets.new-api-key.file = ../secrets/new-api-key.age;

# Rebuild:
zion switch
```

---

## External Resources

- **agenix:** https://github.com/ryantm/agenix
- **sops-nix:** https://github.com/Mic92/sops-nix
- **age encryption:** https://age-encryption.org/
- **Docker secrets best practices:** https://docs.docker.com/engine/swarm/secrets/
- **gitleaks docs:** https://gitleaks.io/

---

## Credentials Currently Exposed (For Team Reference)

**⚠️ These must be rotated ASAP:**

| Service | Credential | Locations |
|---|---|---|
| PDF Kit | `API_PDF_KIT_TOKEN` (dev & prod) | front-student, bo-container local/prod.env |
| Sentry | `SENTRY_DSN` | bo-container/env/local.env (auth token in URL) |
| Pagar.me | `PAGARME_MERCHANT`, `PAGARME_ACCOUNT` | bo-container/env/local.env |
| Google OAuth | `GOOGLE_CLIENT_ID` | Multiple (dev: `396782692033-...`, prod: `163919811078-...`) |
| hCaptcha | `HCAPTCHA_SITE_KEY` | Multiple (same value: `6056644e-aaba-42a0-b870-35fed5faefe6`) |
| AWS S3 | Bucket name: `estrategia-prod-questoes` | bo-container/env/local.env |

---

## Questions?

- Sentinel agent (security): `/home/pedrinho/.ovault/Work/vault/agents/sentinel/memory.md`
- Zion CLI: `zion man`
- NixOS secrets: See nixos wiki on agenix/sops-nix
