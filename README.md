# UC Davis License Provisioning Notification - Meeting Brief (2026-10-29)

## Customer ask

UC Davis wants to explore a custom automated solution for license provisioning events that can:

1. Detect when new licenses are provisioned.
2. Notify a designated distribution list.
3. Include key provisioning details in the notification.
4. Maintain an audit trail of provisioning and notification activity.

## Meeting context

- **Customer participant:** Peter Carroll (UC Davis)
- **Organizer:** Chris DeLeon
- **Also invited:** Rick Leos and Copilot support
- **Meeting date:** 2026-10-29

## Discovery focus for the call

The primary design decision is the event source and detection strategy (event-driven vs polling) for reliable license provisioning capture.

Key requirements to confirm:

1. **License scope:** M365, Power Platform, Dynamics 365, Copilot, or all.
2. **Provisioned definition:** tenant SKU increase/new SKU, user assignment, or both.
3. **Notification latency target:** near real-time or scheduled polling cadence.
4. **Required notification payload:** SKU, counts, user, initiator, timestamp, source id, etc.
5. **Audit system of record:** Dataverse, SharePoint, Log Analytics, or another platform.
6. **Notification channel(s):** email DL, Teams, ServiceNow, or ITSM integration.

## Architecture direction

Once requirements are confirmed, validate whether **Power Automate + Microsoft Graph + Dataverse** satisfies:

- Detection fidelity (including overlap + dedupe for audit log latency),
- Operational reliability (retry/error handling),
- Compliance and reporting needs (audit retention, queryability, export/reporting).

If constraints exceed connector/runtime limits, evaluate an **Azure-centric** implementation path.
