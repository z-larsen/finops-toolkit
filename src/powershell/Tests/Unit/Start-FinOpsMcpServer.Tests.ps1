# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

& "$PSScriptRoot/../Initialize-Tests.ps1"

InModuleScope 'FinOpsToolkit' {
    Describe 'Start-FinOpsMcpServer' {

        Context 'Command availability' {
            It 'Should be exported as a public command' {
                $cmd = Get-Command -Name 'Start-FinOpsMcpServer' -Module 'FinOpsToolkit' -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
            }

            It 'Should have CmdletBinding attribute' {
                $cmd = Get-Command -Name 'Start-FinOpsMcpServer' -Module 'FinOpsToolkit'
                $cmd.CmdletBinding | Should -BeTrue
            }
        }

        Context 'File dependencies' {
            It 'Should have the MCP server script' {
                $serverPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Private/FinOpsMultitool/Start-McpServer.ps1'
                Test-Path -Path $serverPath | Should -BeTrue
            }
        }

        Context 'Behavior' {
            It 'Should write an error when the server script is missing' {
                Mock Test-Path { $false }
                { Start-FinOpsMcpServer -ErrorAction Stop } | Should -Throw '*installation may be incomplete*'
            }

            It 'Should not attempt to start the server when the script is missing' {
                Mock Test-Path { $false }
                Start-FinOpsMcpServer -ErrorAction SilentlyContinue
                Should -Invoke Test-Path -Times 1 -Exactly
            }
        }

        Context 'Parameters' {
            It 'Should expose an optional WriteMode parameter' {
                $cmd = Get-Command -Name 'Start-FinOpsMcpServer' -Module 'FinOpsToolkit'
                $cmd.Parameters.ContainsKey('WriteMode') | Should -BeTrue
            }

            It 'Should restrict WriteMode to the write-safety modes' {
                $cmd = Get-Command -Name 'Start-FinOpsMcpServer' -Module 'FinOpsToolkit'
                $validateSet = $cmd.Parameters['WriteMode'].Attributes |
                    Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
                $validateSet.ValidValues | Should -Be @('ReadOnly', 'Interactive', 'Enforced')
            }

            It 'Should default to leaving the environment write mode untouched' {
                $cmd = Get-Command -Name 'Start-FinOpsMcpServer' -Module 'FinOpsToolkit'
                $cmd.Parameters['WriteMode'].Attributes.Mandatory | Should -Not -Contain $true
            }
        }
    }
}
