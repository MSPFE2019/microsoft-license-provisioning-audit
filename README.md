# Microsoft License Provisioning Audit - ALM-Ready Power Platform Solution

This repository is structured for **Power Platform ALM best practices**: source-controlled solution components, repeatable build, automated validation, and managed deployment by environment.

## Solution scope

The solution detects provisioning activity and keeps an auditable notification history:

1. Tenant-level license provisioning detection (`subscribedSkus` baseline compare)
2. User-level license assignment detection (`directoryAudits` with overlap + dedupe)
3. Grouped digest notifications with retry tracking
4. Dataverse audit trail (`LicenseSnapshot`, `ProvisioningEvent`, `DetectionCheckpoint`)

## ALM implementation in this repo

### 1) Source-first structure

- `src/solutions/microsoft-license-provisioning-audit/` stores unpacked solution source.
- Build artifacts are generated into `out/` and ignored by Git.
- No environment-specific values are hard-coded into source.

### 2) Environment parameterization

Deployment settings files are split by stage:

- `config/deploymentSettings.dev.json`
- `config/deploymentSettings.test.json`
- `config/deploymentSettings.prod.json`

Each file maps:

- Environment variable values
- Connection references

### 3) Automated validation and packaging

Scripts:

- `scripts/validate-solution.ps1`
  - Packs and unpacks to validate source integrity.
- `scripts/build-solution.ps1`
  - Builds both:
    - `microsoft-license-provisioning-audit_unmanaged.zip`
    - `microsoft-license-provisioning-audit_managed.zip`

### 4) CI quality gate

GitHub Actions workflow:

- `.github/workflows/alm-ci.yml`
  - Installs PAC CLI
  - Runs validation
  - Builds managed/unmanaged zips
  - Publishes solution artifacts

### 5) Controlled managed deployment

GitHub Actions workflow:

- `.github/workflows/deploy-managed.yml`
  - Manual promotion to `test` or `prod`
  - Service principal authentication
  - Managed import with environment-specific settings file

## Required GitHub secrets for deployment workflow

Set these repository/environment secrets:

- `PP_APP_ID`
- `PP_CLIENT_SECRET`
- `PP_TENANT_ID`
- `PP_ENV_URL`

## Local build and validation

Run from repo root:

```powershell
./scripts/validate-solution.ps1
./scripts/build-solution.ps1
```

Outputs:

- `out/microsoft-license-provisioning-audit_unmanaged.zip`
- `out/microsoft-license-provisioning-audit_managed.zip`

## ALM best practices applied

1. **Managed-to-upstream promotion**: deploy managed in test/prod.
2. **Configuration externalization**: values supplied per environment via deployment settings.
3. **Service principal automation**: no interactive auth in CI/CD.
4. **Repeatable builds**: deterministic pack from source.
5. **Environment isolation**: separate deployment profiles and approvals.
6. **Auditability**: event rows include detection + notification lifecycle fields.

## Operational notes

- Existing legacy flow (80% consumption alert) remains in the solution source.
- `cr3f6_Secret` exists as an environment variable; production should use Key Vault-backed secret handling.
- Sovereign cloud routing is supported through `GraphBaseUrl` and `AuthorityUrl` variables, but tenant validation is still required.
