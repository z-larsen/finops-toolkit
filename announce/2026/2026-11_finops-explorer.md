# FinOps Explorer: Where to start with Azure FinOps

Many organizations today know they need to better understand their cost data. There are many tools available that can provide that info but are cumbersome to use. FinOps Explorer, new in FinOps toolkit 16, lets you explore that picture in a single working session. It's a read-only terminal user interface (TUI) for PowerShell (7). You sign in, choose a tenant and its subscription(s), and it explores cost drivers, tagging gaps, idle and orphaned resources, commitment utilization, and more. It works with the cost data you already have, whether that's a FinOps hub, a Cost Management export, or the Cost Management API. You can then get a quick view within the terminal but it will also save a local report, formatted for easy readability that can then be reviewed and shared. Read on to see how a run works and how to try it.

## Let's skip the cold start

When the honest answer to the routine question "where do we stand?" is "We don't know yet," we'll call that the cold start. Getting past it usually means pulling cost data together by hand, chasing down tagging gaps, and sizing optimization opportunities and re-investment opportunities across subscriptions, all before you know where you should even focus.

FinOps Explorer does just that, in one run, so you can spend more time on the follow-up decisions that need to be made. It complements the tools you are likely already using if you're reading this. [FinOps hubs](https://aka.ms/finops/hubs) and [Power BI reports](https://aka.ms/ftk/pbi) cover ongoing reporting. [FinOps workbooks](https://aka.ms/ftk/workbooks) and [Azure Optimization Engine](https://aka.ms/ftk/aoe) shed light on optimization opportunities in the Azure portal. FinOps Explorer lets you explore the same kinds of findings from your terminal, on demand, for exactly the scope you choose.

## What will FinOps Explorer scan?

FinOps Explorer has 26 scans in its menu, grouped the way you'd naturally explore FinOps:

| Area | What it looks at |
| --- | --- |
| Optimization | Orphaned resources, idle VMs, storage tier advice, legacy resources, and Azure Hybrid Benefit opportunities |
| Governance | Tag inventory and recommendations, plus policy inventory and recommendations |
| Cost analysis | Cost data, resource costs, cost by tag, cost trend, and unit economics |
| Commitments | Reservation advice, commitment utilization, and savings realized |
| Monitoring | Budget status, budget history, and anomaly alerts |
| Advisor, sustainability, and AI | Azure Advisor cost recommendations, carbon emissions, and AI workload metrics |
| Account | Billing structure, contract info, and Microsoft Azure Consumption Commitment (MACC) |

You then pick which scans to run. Every scan except Billing Structure starts selected. Billing Structure walks your entire billing account hierarchy, so you turn it on when you want it. If you choose Cost Management exports as your cost source, the menu only lists the scans an export can answer, plus the inventory scans that read Azure directly.

All of the scans are read-only. As of this post FinOps Explorer never creates, changes, or deletes a resource, and it doesn't apply the recommendations it finds. Those decisions stay with you and the people who own the workloads.

## How do you explore?

Exploring takes six steps:

1. **Sign in and choose a tenant.** Run `Start-FinOpsExplorer`. If you're not signed in to Azure, it prompts you to sign in. If you have access to more than one tenant, select the one you want.
2. **Choose a scope.** Scan every subscription in the tenant, or pick one. The first time you explore, start with one subscription so you can check access and data coverage before you widen the scope.
3. **Choose where cost data comes from.** The next section will cover these options.
4. **Choose your scans.** Use the arrow keys to move through the list, the Spacebar to toggle a scan, and select Enter to run the selection.
5. **Watch it run.** A progress bar tracks the run, and each scan reports its result count and how long it took.
6. **Read the report.** When the run finishes, the TUI saves the report to a new folder under `FinOpsToolkit\Explorer\Reports` in your local app data and prints its path.

If your terminal can't draw arrow-key menus, such as a PowerShell remoting session, the TUI switches to numbered prompts on its own. Add `-Accessible` to use them in any terminal.

### Where does the cost data come from?

FinOps Explorer reads cost data from the source you choose. If your source fails, you will see the failure. It never swaps in another one, because a report that blends sources can look complete when it isn't.

- **FinOps hub.** If you run a FinOps hub on Azure Data Explorer or Microsoft Fabric, set `FINOPS_HUB_KUSTO_URI` to its query endpoint and FinOps Explorer queries the hub's database. The engine does the aggregation, so only summaries come back to PowerShell. This is best for large environments. A storage-only hub works too, for smaller datasets.
- **Cost Management exports.** Choose an existing Cost Management export in Azure Storage (CSV or compressed CSV, with actual cost or FOCUS billed cost). You don't need a hub. FinOps Explorer finds likely export locations, and you pick one. You need Storage Blob Data Reader access to read it.
- **Cost Management API.** If you don't have a hub or an export, choose the API and FinOps Explorer queries Cost Management directly. It's the quickest way to start. Costs can lag usage, and API throttling can slow large runs.
- **Resource Graph only.** Skip the scans that need cost data, such as budget history and unit economics, and run the rest.

## How do we read the results?

Open `FinOpsReport.html` in your browser. Explore it in whatever order you like, but we'd start with:

- **FinOps story.** It names the tenant, the scope, the cost source, and the period the data covers, so you always know what the run did and didn't look at.
- **Scan status.** Each scan tells you whether it returned data, returned limited data, found no data, or failed. Check this before you read deep into the results. Missing data is never shown as zero spend.
- **KPI reference.** It maps results to 27 KPIs from the [FinOps Foundation KPI catalog](https://www.finops.org/finops-kpis/) and marks each one computed, unavailable, not run, or informational. Expand a KPI to see its formula and limits.

The KPI reference is our favorite feature. Most people don't know the catalog by name, so the report connects what each scan found to the metrics the FinOps community actually tracks, and you learn the framework as you go instead of needing to know it first. That's intentional. FinOps Explorer was designed with learning in mind throughout.

The run folder also holds one CSV file per scan and a `ScanSummary.txt` summary. A scan that fails or returns nothing still gets a CSV status record, so you can see what happened.

Treat each finding as a starting point for a conversation, not a verdict. A high cost alone isn't evidence of waste, so talk to the workload owner before you change anything.

Reports aren't encrypted, and they can include resource names, tags, and costs. FinOps Explorer saves them in a folder only your account can open, never uploads them, and won't save them to a Git repository, a mapped or UNC network path, or a symbolic link or junction.

## Can an AI agent run the same explore?

Yes. The same investigations ship as agent skills in the [FinOps toolkit agent plugin](https://learn.microsoft.com/cloud-computing/finops/toolkit/agent-plugin/finops-toolkit-agent-plugin-overview#finops-explorer-skills) for GitHub Copilot CLI and Claude Code. The skills tell an agent which investigation answers your question, the Resource Graph and Cost Management queries behind it, and where raw results can mislead. Just like when you explore from the terminal, they're read-only. They report what they find and leave the changes to you.

## How do we get started?

You need PowerShell 7 and the `Az.Accounts`, `Az.ResourceGraph`, and `Az.Storage` modules. Most scans need Reader or Cost Management Reader on the scope you scan. The account scans and commitment utilization read at billing scope, so they also need a billing role for your agreement. Without that access, commitment utilization tells you it couldn't reach a billing scope instead of showing zero commitments.

FinOps Explorer ships in FinOps toolkit 16 and later, so the toolkit's PowerShell module installs it. Here's the short version:

```powershell
Install-Module -Name Az.Accounts
Install-Module -Name Az.ResourceGraph
Install-Module -Name Az.Storage
Install-Module -Name FinOpsToolkit
Connect-AzAccount
Start-FinOpsExplorer
```

The first time you explore, scope it to one subscription:

```powershell
Start-FinOpsExplorer -SubscriptionId '<subscription-id>'
```

Want to run it from a pipeline or a scheduled job? Sign in first, then add `-NonInteractive` along with `-SubscriptionId`, `-Scans`, and `-DataSource`.

The Explorer TUI runs on PowerShell 7. We've verified it on Windows, and we'd like to hear how it goes on macOS and Linux. For more, see the [FinOps Explorer overview](https://learn.microsoft.com/cloud-computing/finops/toolkit/explorer/finops-explorer-overview) and the [Start-FinOpsExplorer command reference](https://learn.microsoft.com/cloud-computing/finops/toolkit/powershell/explorer/start-finopsexplorer).

## What should FinOps Explorer scan next?

Tell us what you find when you explore your environment, and where it doesn't match what you see in the portal. [Create an issue](https://aka.ms/ftk/ideas) or [start a discussion](https://aka.ms/ftk/discuss) to ask for the scans you want next or the changes you'd like in the report.

## Preview snippet

>FinOps Explorer, new in FinOps toolkit 16, is a read-only terminal tool that explores your Azure environment for cost, tagging, and optimization opportunities. Rather than just dumping raw cost totals into a report, you get an intentionally designed FinOps report that teaches you how to read the results by mapping every finding to the KPIs the FinOps community tracks. It's built for people new to FinOps and veterans alike. Point it at a FinOps hub, Cost Management exports, or the Cost Management API, and walk away understanding your cloud spend better than when you started.

## Social media

**LinkedIn:**

> FinOps Explorer is new in FinOps toolkit 16! #FinOpsToolkit
>
> Explore your Azure environment from a terminal and get a local report on cost drivers, tagging gaps, idle and orphaned resources, and commitment utilization. It's read-only, and it works with a FinOps hub, Cost Management exports, or the Cost Management API. #FinOps #Azure
>
> Try it on one subscription, then tell us what you'd like it to scan next.
>
> {{POST_URL}}

**Twitter/X:**

> FinOps Explorer is new in FinOps toolkit 16! #FinOpsToolkit
>
> - A read-only terminal UI for Azure cost scans
> - Works with FinOps hubs, exports, or the API
> - Saves a local report you can share
>
> What should it scan next?
>
> {{POST_URL}}

**Internal:**

> FinOps Explorer is live in FinOps toolkit 16: a read-only terminal UI that explores your Azure environment for cost, tagging, and optimization opportunities and saves a local report. {{POST_URL}}
