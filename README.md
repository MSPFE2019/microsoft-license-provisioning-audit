# Microsoft License Provisioning Audit (Power Platform Solution)

## What this solution does

This Power Platform solution detects new Microsoft license provisioning activity, sends operational notifications, and stores a durable audit trail.

It covers two provisioning signals:

1. **Tenant-level provisioning**
   - New SKU appears in tenant subscriptions.
   - Enabled unit count increases for an existing SKU.
2. **User-level provisioning**
   - License assignments detected from Entra directory audit events (`Change user license`), including group-based assignment activity.

## How it works

The design uses decoupled Power Automate flows, with Dataverse as the system of record.

### Flow 1: Detect Tenant License Provisioning

- Trigger: Recurrence (hourly by default).
- Reads Graph `subscribedSkus`.
- Compares current values to Dataverse `LicenseSnapshot`.
- Writes `ProvisioningEvent` rows with `Pending` notification status for:
  - `TenantSkuNew`
  - `TenantSkuIncrease`
- Updates or creates snapshot rows.
- First run seeds baseline and does not notify.

### Flow 2: Detect User License Assignments

- Trigger: Recurrence (every 15 minutes by default).
- Reads checkpoint watermark from Dataverse `DetectionCheckpoint`.
- Queries Graph `auditLogs/directoryAudits` for `Change user license`.
- Uses overlap window + dedupe strategy to account for log latency.
- Writes `ProvisioningEvent` rows with `Pending` status for `UserLicenseAssigned`.
- Advances checkpoint after successful processing.
- First run establishes checkpoint baseline.

### Flow 3: Send Provisioning Notification

- Trigger: Recurrence (every 15 minutes by default).
- Reads `ProvisioningEvent` rows where:
  - status is `Pending`, or
  - status is `Failed` and retry count is below `MaxRetries`.
- Sends one grouped digest email to `NotificationDL`.
- Optionally posts to Teams when enabled.
- Updates each event row to `Sent` or `Failed` with audit details:
  - channel
  - recipient
  - sent timestamp
  - retry count
  - error message
  - flow run URL

## Power Platform components

### Dataverse tables

1. **LicenseSnapshot**
   - SKU baseline storage for tenant comparison.
2. **ProvisioningEvent**
   - One row per detected event and notification outcome.
3. **DetectionCheckpoint**
   - Polling watermark and run-state tracking.

### Environment variables

- `TenantID`
- `ClientID`
- `Secret`
- `M365GroupID` (legacy 80% usage flow)
- `NotificationDL`
- `PollOverlapMinutes` (default `30`)
- `MaxRetries` (default `3`)
- `EnableTeamsNotification` (default `false`)
- `GraphBaseUrl` (default `https://graph.microsoft.com`)
- `AuthorityUrl` (default `https://login.microsoftonline.com`)

### Connection references

- Dataverse
- Office 365 Outlook
- Teams
- Office 365 Groups (legacy flow)

## Microsoft Graph permissions

Required for app registration used by HTTP actions:

- `Organization.Read.All`
- `AuditLog.Read.All`

Optional:

- `User.Read.All` (if additional user enrichment is needed)

## Notifications and audit behavior

- Notification channel is digest email by default.
- Teams notification is optional.
- Processing is at-least-once with dedupe controls.
- Audit rows are retained for reporting and operational traceability.

## Solution package

- `M365LicenseNotification_1_1_0_0.zip` contains the unmanaged solution package.
- `solution/` contains unpacked solution artifacts.
- `solution-src/` contains source used for packing and maintenance.
