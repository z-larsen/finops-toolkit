# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

<#
    .SYNOPSIS
    Starts the FinOps multitool Model Context Protocol (MCP) server.

    .DESCRIPTION
    The Start-FinOpsMcpServer command starts a Model Context Protocol (MCP) server that
    exposes the FinOps multitool scans as tools an AI agent can call. The server speaks
    JSON-RPC over stdin and stdout, so it is normally launched by an MCP client rather
    than run interactively.

    The scan tools are read-only and cover cost, commitments, budgets, tags, policy, and
    governance. The server also exposes remediation tools, which preview by default and
    are routed through the multitool write-safety gate. Writes stay disabled unless the
    write mode is changed from the default of ReadOnly.

    Requires PowerShell 7 or later, the Az modules (Az.Accounts, Az.ResourceGraph,
    Az.Storage), and an authenticated Azure session with at least Reader access.

    .PARAMETER WriteMode
    Optional write-safety mode for the session, equivalent to setting the
    FINOPS_WRITE_MODE environment variable. ReadOnly blocks every write, Interactive
    allows a write after an explicit preview, and Enforced additionally requires the
    confirmation token returned by the matching preview. When omitted, the existing
    environment value is used, which defaults to ReadOnly.

    .EXAMPLE
    Start-FinOpsMcpServer

    Starts the MCP server in read-only mode. Configure an MCP client to run this command
    rather than calling it directly.

    .EXAMPLE
    Start-FinOpsMcpServer -WriteMode Enforced

    Starts the MCP server with remediation enabled, requiring a confirmation token from a
    preview before any change is applied.

    .LINK
    https://aka.ms/ftk/Start-FinOpsMcpServer
#>
function Start-FinOpsMcpServer {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Start-FinOpsMcpServer starts a stdio protocol server. The remediation tools it exposes preview by default and are gated by the multitool write-safety policy.')]
    [OutputType([void])]
    param(
        [Parameter()]
        [ValidateSet('ReadOnly', 'Interactive', 'Enforced')]
        [string]$WriteMode
    )

    $multitoolRoot = Join-Path -Path $PSScriptRoot -ChildPath '../Private/FinOpsMultitool'
    $serverScript = Join-Path -Path $multitoolRoot -ChildPath 'Start-McpServer.ps1'

    if (-not (Test-Path -Path $serverScript)) {
        Write-Error "FinOps multitool files not found at '$multitoolRoot'. The module installation may be incomplete."
        return
    }

    if ($PSBoundParameters.ContainsKey('WriteMode')) {
        $env:FINOPS_WRITE_MODE = $WriteMode
    }

    # Run in-process: the server owns stdin/stdout for the JSON-RPC stream.
    & $serverScript
}
