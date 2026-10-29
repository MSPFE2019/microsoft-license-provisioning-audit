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

## Download-ready solution packages

Use these files directly for import:

- `solution-packages/microsoft-license-provisioning-audit_1_1_0_0_unmanaged.zip` (dev/customization)
- `solution-packages/microsoft-license-provisioning-audit_1_1_0_0_managed.zip` (test/prod)

## Step-by-step: create the flows in Power Platform

### 1) Prepare prerequisites

1. In Entra ID, create/register an app for Microsoft Graph.
2. Grant **Application permissions**: `Organization.Read.All` and `AuditLog.Read.All`; grant admin consent.
3. Create a client secret for the app.
4. In Power Platform, ensure Dataverse is enabled in your target environment.
5. Create required connections:
   - Dataverse
   - Office 365 Outlook (service account/shared mailbox)
   - HTTP with Entra ID (or equivalent Graph-authenticated HTTP connector)

### 2) Import the solution

1. Go to **Power Apps -> Solutions -> Import solution**.
2. Import `microsoft-license-provisioning-audit_1_1_0_0_unmanaged.zip` in development.
3. During import, bind connection references to your environment connections.
4. Set environment variable values:
   - `cr3f6_TenantID`
   - `cr3f6_ClientID`
   - `cr3f6_Secret`
   - `cr3f6_NotificationDL`
   - `cr3f6_PollOverlapMinutes` (default `30`)
   - `cr3f6_MaxRetries` (default `3`)
   - `cr3f6_EnableTeamsNotification` (`No` by default)
   - `cr3f6_GraphBaseUrl` (`https://graph.microsoft.com`)
   - `cr3f6_AuthorityUrl` (`https://login.microsoftonline.com`)
   - `cr3f6_M365GroupID` (used by the legacy utilization flow)

### 3) Verify Dataverse components

1. Confirm tables exist:
   - `cr3f6_LicenseSnapshot`
   - `cr3f6_ProvisioningEvent`
   - `cr3f6_DetectionCheckpoint`
2. Create the two security roles manually (role privilege XML is environment-dependent, so it is **not** packaged in the solution zip — only JSON specs are provided as a reference):
   - `cr3f6_LicenseAuditReader` — read-only on the three tables above. Spec: `src/solutions/microsoft-license-provisioning-audit/securityroles/cr3f6_LicenseAuditReader.role.json`
   - `cr3f6_LicenseAuditService` — read/write/create (no delete) on the three tables above, for the flows' connection identity. Spec: `src/solutions/microsoft-license-provisioning-audit/securityroles/cr3f6_LicenseAuditService.role.json`

### 4) Enable flows in the right order

1. Turn on **Detect Tenant License Provisioning** (hourly).
2. Turn on **Detect User License Assignments** (every 15 minutes).
3. Turn on **Send Provisioning Notification** (every 15 minutes).
4. Keep **Get License Usage** enabled only if you still want the legacy 80% utilization alert.

### 5) First-run behavior

1. Tenant detector seeds the `LicenseSnapshot` baseline on first run (no notifications).
2. User detector creates the initial checkpoint baseline on first run (no notifications).
3. Subsequent runs create `ProvisioningEvent` rows with `Pending` status.

### 6) Notification behavior

1. Notifier groups pending events into one digest email to `NotificationDL`.
2. On success, events are marked `Sent`.
3. On failure, events are marked `Failed` and retried up to `MaxRetries`.
4. Optional Teams notification is controlled by `EnableTeamsNotification`.

### 7) Functional test procedure

1. Add a small number of licenses to the tenant (or assign a test license to a user).
2. Wait for detector schedules to run.
3. Confirm new rows in `cr3f6_ProvisioningEvent`.
4. Confirm digest email delivery to the distribution list.
5. Confirm each event has updated notification fields (`NotificationStatus`, `NotificationSentOn`, `RetryCount`, `FlowRunUrl`).

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
- Security roles are **not** imported with the solution zip (Dataverse role privilege XML is environment-dependent). Create them manually in the target environment from the JSON specs in `securityroles/`.
- Alternate keys are not used on `cr3f6_ProvisioningEvent`/`cr3f6_LicenseSnapshot`; duplicate avoidance relies on check-before-create logic in the flows plus serialized runs.
