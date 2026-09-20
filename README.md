# Agent for Setup — Salesforce Admin Copilot

An Agentforce agent (built on the Salesforce DX / metadata framework) that helps Salesforce admins answer day-to-day org-management questions in natural language — permissions, licenses, and the setup audit trail — instead of digging through Setup pages and SOQL queries by hand.

## Functional Overview

**Agent for Setup** (`genAiPlanners/Agent_for_Setup`) is a ReAct-style Agentforce planner exposed to admins as a conversational assistant. It routes each user question to one of several topics ("plugins"), each backed by Apex actions and/or prompt-template actions that query live org data.

### What it can do

1. **User Access Management** — "Does Benjamin have access to the Opportunity object?", "What permissions does Benjamin need to convert a lead?"
   - Resolves a user or object mentioned by name to its record/API name.
   - Looks up a permission's API name from documentation when the user only gives a description.
   - Retrieves and explains a user's `ObjectPermissions`/`FieldPermissions`, or lists users who hold a given permission.
   - Answers with an explicit Yes/No plus the profile/permission set that grants (or fails to grant) access, and never surfaces raw JSON to the user.

2. **Salesforce License Management** — "Which licenses are running low?", "What license types do we have?"
   - Analyzes `UserLicense` totals vs. used counts across the org and flags licenses that need replenishing.

3. **Salesforce Setup Audit Trail** — "What did Sarah change in Setup on March 3rd?"
   - Retrieves `SetupAuditTrail` entries for a given user and date and summarizes the admin actions taken, with guidance on interpreting audit trail entries and configuring audit trail notifications.

4. **Fallback / general Setup guidance** — falls back to Salesforce Help documentation search when no topic matches, rather than letting the model guess an answer.

## Technical Components

### Apex invocable actions (`force-app/main/default/classes`)

| Class | Purpose |
|---|---|
| `UserPermissionRetrieval.cls` | Given a permission API name, queries `PermissionSetAssignment` + `User` to return the list of users holding that permission. |
| `OrgPermissions.cls` | Given an entity type (`ObjectPermissions` or `FieldPermissions`) and object/field API name, returns the matching permission records (who has read/create/edit/delete access, via which profile/permission set). |
| `OrgLicenseInformation.cls` | Queries `UserLicense` for name, total, and used license counts across the org. |
| `SummarizeAuditTrail.cls` | Queries `SetupAuditTrail` for a given `CreatedById` and date, returning the action/section/display fields for that user's admin activity. |

Each class exposes a single `@InvocableMethod` with typed `Request`/`Response` inner classes so it can be wired directly into an Agentforce action (`invocationTargetType: apex`).

### Agentforce metadata (`force-app/main/default/genAi*`)

- **`genAiPlanners/Agent_for_Setup`** — the top-level ReAct planner that ties the topics together and defines the agent's master label ("Agent for Setup").
- **`genAiPlugins/`** — topic definitions (scope, instructions/guardrails, and which functions each topic can call):
  - `Salesforce_License_Management` → uses `User_License_Analysis`.
  - `Salesforce_Setup_Audit_Trail` → uses `Setup_Audit_Trail_Summary` and record-lookup.
  - `UserAccessManagement` (defined inline in the planner) → chains object/user identification, permission-name lookup, and the permission-retrieval actions above, with explicit instructions to disambiguate pronouns/multiple matches and to never show raw JSON.
- **`genAiFunctions/`** — individual action definitions bridging the planner to either Apex or a prompt template, each with an `input/schema.json` and `output/schema.json` describing the parameters the LLM must supply and the shape of the result:
  - `Get_Users_With_Permission` → Apex (`UserPermissionRetrieval`).
  - `Object_Field_Permission_Analysis` → prompt template over `OrgPermissions` data.
  - `Retrieve_Permission_API_Name_From_Documentation` → prompt template that maps a natural-language permission description to its API name.
  - `Setup_Audit_Trail_Summary` → prompt template over `SummarizeAuditTrail` data.
  - `User_License_Analysis` → prompt template over `OrgLicenseInformation` data.
- **`genAiPromptTemplates/`** — the actual LLM prompt templates invoked by the `generatePromptResponse` functions above, one per analysis action.

### Project scaffolding

- Standard **Salesforce DX** project (`sfdx-project.json`, `force-app/main/default` source layout, `manifest/package.xml`), API version 63.0.
- `config/project-scratch-def.json` — scratch org definition for local development.
- `scripts/apex`, `scripts/soql` — sample Apex/SOQL scripts for ad hoc testing against an org.
- Tooling: ESLint + Prettier (incl. Apex/XML plugins) enforced via Husky pre-commit + `lint-staged`; Jest (`sfdx-lwc-jest`) configured for LWC unit tests, though no LWC/Aura components are currently implemented beyond the linter scaffolding.

## Getting Started

```bash
# Authenticate to an org
sf org login web -a myOrg

# Deploy the agent metadata and Apex classes
sf project deploy start -o myOrg

# Or push to a scratch org created from config/project-scratch-def.json
sf org create scratch -f config/project-scratch-def.json -a myScratchOrg
sf project deploy start -o myScratchOrg
```

After deployment, activate **Agent for Setup** in Setup → Agentforce Agents to make it available to admin users.
