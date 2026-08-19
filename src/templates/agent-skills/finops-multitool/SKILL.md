---
name: finops-multitool
description: This skill should be used when the user asks to "scan for cost savings", "find orphaned resources", "find idle VMs", "check Azure Hybrid Benefit", "review tags", "tag coverage", "tag recommendations", "policy coverage", "cost by tag", "cost trend", "top resources by cost", "reservation recommendations", "commitment utilization", "realized savings", "budget status", "cost anomaly alerts", "Advisor cost recommendations", "billing structure", "contract info", or run a "FinOps assessment", "FinOps scan", or "cost optimization scan" using the FinOps multitool MCP server. Also use it proactively whenever the conversation turns to Azure cost, waste, savings, governance, or FinOps health and a live read-only scan would answer the question.
license: MIT
compatibility: Requires the finops-multitool MCP server to be running (started with `Start-FinOpsMcpServer` from the FinOpsToolkit module) and an authenticated Azure session (Connect-AzAccount) with at least Reader access. The scan tools are read-only; four write/remediation tools are dry-run by default, gated by a write-safety policy, and disabled unless FINOPS_WRITE_MODE is set (the server defaults to ReadOnly).
metadata:
  author: microsoft
  version: '1.0'
---

# FinOps multitool

The FinOps multitool MCP server exposes 13 tools that scan a live Azure environment for cost savings, governance gaps, and FinOps health. Most scans are reached through two routers - `run_scan` and `run_cost_scan` - which take the scan name as an argument rather than being a tool each. A third router, `remediate`, covers the write actions: delete an orphaned resource, deallocate an idle VM, and enable Azure Hybrid Benefit. Those are dry-run by default and gated by a configurable write-safety policy. Use the server to ground answers about waste, savings, tags, policy, budgets, and commitments in the customer's actual resource state instead of guessing.

The analysis tools query Azure Resource Graph, Cost Management, and Azure Advisor with **Reader** scope and never modify resources. The four write tools (`remediate` with `delete_orphaned_resource`, `remediate` with `deallocate_vm`, `remediate` with `enable_hybrid_benefit`, and `set_cost_allocation_rule`) are the only ones that can change Azure, and only when explicitly applied: they preview by default (`apply=false`), route through a write-safety gate (protected-tag / resource-group / subscription guardrails, estimated-impact and blast-radius caps, and an append-only audit log), and are disabled entirely unless an operator sets `FINOPS_WRITE_MODE` - the server defaults to `ReadOnly`, which blocks all writes. Be proactive: when a user raises a cost, waste, savings, or governance topic, offer to run the matching scan rather than answering abstractly.

## When to use the server

Run a scan whenever the user wants real numbers from their environment. Examples that should trigger a tool call:

- "Where am I wasting money?" → `run_scan` with `orphaned_resources`, then `idle_vms`, then `run_full_scan` if they want the full picture
- "Are we using reservations well?" → `run_scan` with `commitment_utilization`, then `reservation_advice`
- "What's our tag coverage?" → `run_scan` with `tag_inventory`
- "Break cost down by CostCenter / team / app" → `run_cost_scan` with `cost_by_tag` (run `run_scan` with `tag_inventory` first)
- "Run a FinOps assessment" → `run_full_scan`

If the user is only asking a conceptual question ("what is Azure Hybrid Benefit?"), answer directly — don't force a scan.

## Tool routing

Pick the narrowest tool that answers the question. Use `run_full_scan` only for a broad assessment.

Most scans go through `run_scan`, passing the scan name in the `scan` argument:

| Intent                                                  | `run_scan` value         | Category       |
| ------------------------------------------------------- | ------------------------ | -------------- |
| Orphaned disks, NICs, public IPs, NSGs, deallocated VMs | `orphaned_resources`     | Optimization   |
| Idle / underutilized VMs (<5% CPU)                      | `idle_vms`               | Optimization   |
| Storage tier optimization (Hot→Cool/Cold/Archive)       | `storage_tier_advice`    | Optimization   |
| Windows/SQL not using Azure Hybrid Benefit              | `ahb_opportunities`      | Optimization   |
| Retiring SKUs and API versions                          | `legacy_resources`       | Optimization   |
| Tag coverage, tag names, untagged resources             | `tag_inventory`          | Governance     |
| Tag quality fixes (CAF gaps, casing, duplicates)        | `tag_recommendations`    | Governance     |
| Azure Policy assignments + compliance                   | `policy_inventory`       | Governance     |
| Policy coverage gaps + recommended guardrails           | `policy_recommendations` | Governance     |
| Month-over-month cost trend                             | `cost_trend`             | Cost           |
| Cost per business unit                                  | `unit_economics`         | Cost           |
| Reservation purchase recommendations                    | `reservation_advice`     | Commitments    |
| Reservation / savings plan utilization                  | `commitment_utilization` | Commitments    |
| Realized savings (RI, SP, AHB)                          | `savings_realized`       | Commitments    |
| MACC commitment burn-down                               | `macc_commitment`        | Commitments    |
| Budget consumption vs thresholds                        | `budget_status`          | Monitoring     |
| Budget history over trailing months                     | `budget_history`         | Monitoring     |
| Cost anomaly alerts + detection rules                   | `anomaly_alerts`         | Monitoring     |
| Advisor cost recommendations                            | `optimization_advice`    | Advisor        |
| Carbon emissions                                        | `carbon`                 | Sustainability |
| Billing account hierarchy (EA/MCA/CSP)                  | `billing_structure`      | Account        |
| Agreement, offer, currency, support plan                | `contract_info`          | Account        |

Cost-family scans go through `run_cost_scan`, which also accepts `dataSource`:

| Intent                                | `run_cost_scan` value | Category |
| ------------------------------------- | --------------------- | -------- |
| Current month actual + forecast spend | `cost_data`           | Cost     |
| Top resources by cost                 | `resource_costs`      | Cost     |
| Cost broken down by tag key/value     | `cost_by_tag`         | Cost     |
| Azure AI / OpenAI spend               | `ai_workloads`        | Cost     |

These stay separate tools because their parameters differ:

| Intent                                           | Tool                        |
| ------------------------------------------------ | --------------------------- |
| Decide hub vs live API before a cost scan        | `detect_cost_data_source`   |
| Confirm which tenant/subscription is active      | `get_azure_context`         |
| Full FinOps assessment across all modules        | `run_full_scan`             |
| Cost breakdown for one VM                        | `scan_vm_cost_breakdown`    |
| Billing accounts + cost allocation eligibility   | `scan_billing_account`      |
| Split shared platform cost across spokes         | `scan_allocate_shared_cost` |
| Split shared cost by telemetry (AKS, APIM, AOAI) | `scan_usage_allocation`     |
| Create/update a native cost allocation rule      | `set_cost_allocation_rule`  |
| Explore the FinOps KPI catalog                   | `explore_finops_kpis`       |
| Power BI template / hub connection               | `powerbi`                   |

## Write / remediation tools

The `remediate` router covers three actions that change Azure, and `set_cost_allocation_rule` is a fourth. They are **not** part of `run_full_scan` and never run implicitly. Each is **dry-run by default** and routes through the write-safety gate. Treat them as opt-in actions a user explicitly approves, not scans.

| Action                                                        | Tool and argument                        | Reversible?                      |
| ------------------------------------------------------------- | ---------------------------------------- | -------------------------------- |
| Delete one orphaned resource (disk, NIC, public IP, snapshot) | `remediate` / `delete_orphaned_resource` | No - irreversible                |
| Deallocate one idle VM                                        | `remediate` / `deallocate_vm`            | Yes - start the VM to undo       |
| Enable Azure Hybrid Benefit on one VM                         | `remediate` / `enable_hybrid_benefit`    | Yes - savings-only               |
| Create/update a native cost allocation rule (chargeback)      | `set_cost_allocation_rule`               | Yes - update/deactivate the rule |

How to drive them safely:

1. **Always preview first.** Call with `apply=false` (the default). The result shows the exact change and a `ConfirmationToken`.
2. **Show the user the preview and get explicit approval.** Never set `apply=true` on your own initiative.
3. **Then apply.** Call again with `apply=true`. In `Enforced` mode you must also pass the `confirmationToken` from the matching preview.
4. **Writes are opt-in.** If `FINOPS_WRITE_MODE` is unset or `ReadOnly` (the default), every write is blocked - the tool returns a `Blocked` result explaining how to enable writes. Do not tell the user a change was applied unless the result has `Applied = true`.

## FinOps hub data paths (cost scans)

The cost-family scans (`run_cost_scan` with `cost_data`, `run_cost_scan` with `resource_costs`, `run_cost_scan` with `cost_by_tag`) read from a FinOps hub when one is available, choosing a path automatically. Call `detect_cost_data_source` first to see which path covers the scope and how fresh it is. Two of the three paths push aggregation **into the Kusto engine** and return only summarized results, so they scale to large customer datasets (tens of GB / hundreds of millions of rows) — the raw rows are never loaded into PowerShell:

| Path                           | When                                                        | Notes                                                                                                  |
| ------------------------------ | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Kusto — online**             | A deployed hub with an Azure Data Explorer / Fabric cluster | Cluster discovered via Resource Graph; aggregation runs in KQL against the `Costs` function. Scalable. |
| **Kusto — offline (ftklocal)** | The exports loaded into a local ftklocal Kusto emulator     | Set `FINOPS_HUB_KUSTO_URI` (anonymous local query). Scalable.                                          |
| **Storage export reader**      | Small datasets, or no Kusto cluster present                 | Reads hub parquet/CSV and aggregates in PowerShell. Convenience fallback, not the scalable path.       |

When a result's `source` is `FinOpsHubKusto`, it came from the engine (summaries only). Forecast is not included on the hub fast paths — call with `dataSource=api` for a live forecast. The `dataSource` argument (`auto` default / `hub` / `api`) lets you force the hub path or the live Cost Management API.

## Scope: subscriptionId

Every tool takes an optional `subscriptionId`.

- **Omit it** and the tool scans **every accessible subscription**. In large tenants this can mean hundreds of subscriptions — slow, and the result is written to a file you must read back.
- **Pass it** to scope to one subscription. Prefer this when the user only has access to (or only cares about) a single subscription, or when iterating quickly.

Always confirm scope before a broad scan if the tenant is large. If the user says they only have access to one subscription, always pass that `subscriptionId`.

## Tool dependencies

Three scans depend on inventory data being gathered first. When calling them individually, run the prerequisite first:

| Scan                                  | Run first                       |
| ------------------------------------- | ------------------------------- |
| `run_cost_scan` / `cost_by_tag`       | `run_scan` / `tag_inventory`    |
| `run_scan` / `tag_recommendations`    | `run_scan` / `tag_inventory`    |
| `run_scan` / `policy_recommendations` | `run_scan` / `policy_inventory` |

`run_full_scan` handles this chaining automatically — it gathers inventory before the dependent modules, so you don't need to sequence calls yourself when running the full assessment.

## run_full_scan

`run_full_scan` executes every module (Optimization, Governance, Cost Analysis, Commitments, Monitoring, Advisor) and returns one comprehensive object. Use the optional `modules` array to run a subset:

- Full assessment: call with no arguments (or just `subscriptionId`).
- Targeted multi-module: pass `modules` (e.g., `["scan_cost_by_tag"]`) to run only those, with dependencies resolved automatically.

Prefer individual tools for a single question — `run_full_scan` is heavier and returns a large payload.

## Reading results

Tool output is JSON. Large results (tag inventory, full scans) are written to a file and the tool returns the file path — read that file to get the data. Each result includes a `permission` block (`role`, `scope`, `api`) confirming the read-only access path used.

When summarizing for the user:

- Lead with the headline number (count, total savings, coverage %).
- Group findings by impact (High/Medium/Low) when the data provides it.
- Translate raw findings into action (e.g., "3 deallocated VMs — the disks keep billing; delete if unused").
- Surface the cost driver, not just the inventory.

## Interpreting common results

- **`run_cost_scan` with `cost_by_tag` returns `NoTagsFound` but resources are tagged.** The tag exists on resources but isn't appearing in cost data. Two usual causes: (1) the tag isn't enabled as a **cost-allocation dimension** in Cost Management settings, or (2) **month-to-date lag** — tag-dimensioned cost data hasn't populated yet. Run `run_scan` with `tag_inventory` to confirm the tag is applied, then advise enabling tag-based cost allocation.
- **Deallocated VMs in `run_scan` with `orphaned_resources`.** Compute isn't billing, but attached managed disks and static public IPs still are. Recommend deleting if truly unused.
- **Low tag coverage in `run_scan` with `tag_inventory`.** Pair with `run_scan` with `tag_recommendations` to flag casing/duplicate issues (e.g., `managed_by` vs `managedBy`) and missing CAF-standard tags.
- **Empty cost results early in the month.** Cost Management data lags; note this rather than reporting "$0".

## FinOps skill ecosystem

The multitool is the data engine. Once a scan surfaces a finding, hand off to the skill that turns it into a decision, a design, or an artifact. Treat this as the routing hub for the wider FinOps practice:

| After this scan / question                                                                                                       | Hand off to                   | For                                                                                                          |
| -------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Any spend question (`run_cost_scan` with `cost_data`, `run_cost_scan` with `resource_costs`, `run_cost_scan` with `cost_by_tag`) | `cost-data-source`            | Choose the scalable hub (Kusto) or storage path vs the live API, warn before slow scans, chunk large tenants |
| `run_scan` with `tag_inventory`, `run_cost_scan` with `cost_by_tag`                                                              | `cost-allocation`             | Showback/chargeback model, shared-cost splitting, tag strategy                                               |
| `run_scan` with `tag_recommendations`, `run_scan` with `policy_recommendations`                                                  | `azure-policy-governance`     | Enforce tags/regions/SKUs via Azure Policy (Bicep/ARM)                                                       |
| `run_scan` with `policy_inventory` results                                                                                       | `azure-workbooks-finops`      | Live in-portal Governance/Optimization workbooks                                                             |
| `run_scan` with `cost_trend`, `run_cost_scan` with `resource_costs`                                                              | `power-bi-finops`             | Dashboards and visuals on cost data                                                                          |
| `run_scan` with `savings_realized`, `run_scan` with `commitment_utilization`                                                     | `unit-economics`              | ESR, cost-per-unit, coverage/utilization KPIs                                                                |
| `run_scan` with `reservation_advice`, `run_scan` with `ahb_opportunities`                                                        | `rate-optimization-portfolio` | RI/SP/AHB portfolio mix and purchase planning                                                                |
| `run_scan` with `budget_status`, `run_cost_scan` with `cost_data`                                                                | `forecasting-budgeting`       | Forecasts, budget design, variance analysis                                                                  |
| `run_scan` with `anomaly_alerts`                                                                                                 | `anomaly-investigation`       | Root-cause a spike down to the resource/change                                                               |
| `run_scan` with `orphaned_resources`, `run_scan` with `idle_vms`                                                                 | `sustainability-carbon`       | Carbon co-benefit of removing waste                                                                          |
| Any deep KQL / FinOps hub query                                                                                                  | `finops-toolkit`              | Kusto analytics on the Hub database                                                                          |
| Single-instrument commitment mechanics                                                                                           | `azure-cost-management`       | Reservations, savings plans, budgets, exports detail                                                         |
| Cost data looks wrong/incomplete                                                                                                 | `focus-data-quality`          | FOCUS conformance, completeness, mapping                                                                     |
| Any finding the user wants written up                                                                                            | `finops-reporting`            | Exec summaries, QBRs, variance narratives                                                                    |

Run the scan first to ground the numbers, then route to the matching skill — don't answer governance, allocation, or reporting questions abstractly when a scan can provide the real state.

## Prerequisites

- The `finops-multitool` MCP server must be running. It's defined in `.vscode/mcp.json` and started via the MCP server list in VS Code.
- An authenticated Azure session is required (`Connect-AzAccount`). Tools fail or hang without it.
- The scan tools are read-only (Reader) and advisory. Four write/remediation tools can modify Azure, but only when an operator opts in via `FINOPS_WRITE_MODE` (default `ReadOnly` blocks all writes) and only after an explicit `apply=true` on the specific previewed change.
