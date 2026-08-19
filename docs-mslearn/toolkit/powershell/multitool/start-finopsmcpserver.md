---
title: Start-FinOpsMcpServer command
description: Start the FinOps multitool Model Context Protocol server so an AI agent can run FinOps scans against a live Azure environment.
author: z-larsen
ms.author: zlarsen
ms.date: 08/19/2026
ms.topic: reference
ms.service: finops
ms.subservice: finops-toolkit
ms.reviewer: micflan
#customer intent: As a FinOps user, I want to understand how to use the Start-FinOpsMcpServer command in the FinOpsToolkit module.
---

# Start-FinOpsMcpServer command

The **Start-FinOpsMcpServer** command starts a Model Context Protocol (MCP) server that exposes the FinOps multitool scans as tools an AI agent can call. The server communicates using JSON-RPC over standard input and output, so it's normally started by an MCP client rather than run interactively.

The scan tools are read-only and cover cost, commitments, budgets, tags, policy, and governance. The server also exposes remediation tools, which preview by default and are routed through the multitool write-safety gate. Writes stay disabled unless you change the write mode from the default of `ReadOnly`.

The command requires PowerShell 7 or later, the `Az.Accounts`, `Az.ResourceGraph`, and `Az.Storage` modules, and an authenticated Azure session with at least Reader access on the target scope.

<br>

## Syntax

```powershell
Start-FinOpsMcpServer `
    [-WriteMode <string>] `
    [<CommonParameters>]
```

<br>

## Parameters

| Name         | Description                                                                                                                                                                                                                  |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `‑WriteMode` | Optional. Write-safety mode for the session, equivalent to the `FINOPS_WRITE_MODE` environment variable. Allowed values are `ReadOnly`, `Interactive`, and `Enforced`. When omitted, the existing environment value is used. |

<br>

## Write-safety modes

| Mode          | Behavior                                                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------------------------ |
| `ReadOnly`    | Default. Every write is blocked. Only the read-only scan tools are usable.                                         |
| `Interactive` | A write is allowed after an explicit preview. Intended for a person reviewing each change in a chat session.       |
| `Enforced`    | A write also requires the single-use confirmation token returned by the matching preview. Intended for automation. |

<br>

## Examples

The following examples demonstrate how to use the Start-FinOpsMcpServer command.

### Configure an MCP client

Most users never run the command directly. Instead, point an MCP client at it:

```json
{
  "servers": {
    "finops-multitool": {
      "type": "stdio",
      "command": "pwsh",
      "args": ["-NoProfile", "-Command", "Start-FinOpsMcpServer"],
      "env": {
        "FINOPS_WRITE_MODE": "ReadOnly"
      }
    }
  }
}
```

### Start the server in read-only mode

```powershell
Start-FinOpsMcpServer
```

Starts the server with every write blocked.

### Start the server with remediation enabled

```powershell
Start-FinOpsMcpServer -WriteMode Enforced
```

Starts the server so remediation tools can apply a change, but only when the agent passes the confirmation token from the matching preview.

<br>

## Related content

Related solutions:

- [FinOps multitool commands](finops-multitool-commands.md)
- [Start-FinOpsMultitool](Start-FinOpsMultitool.md)
- [FinOps toolkit PowerShell module](../powershell-commands.md)

<br>
