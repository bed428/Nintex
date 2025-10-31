<#
Script 1: Discover and Inventory All Nintex Workflows
Description:
    This script runs the nwadmin.exe utility to find all Nintex workflows in the farm and parses the output into a structured CSV file. Run this script from the SharePoint Management Shell on a server where Nintex Workflow is installed.
Prerequisites:
    Proper permissions to execute a nwadmin command.
    Nintex licensed.
#>

# --- CONFIGURATION ---
    $nwadminPath = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN\NWAdmin.exe"
    $outputCsvPath = "C:\Temp\NintexWorkflowInventory.csv"
# ---------------------

# Verify nwadmin.exe exists
    if (-not (Test-Path $nwadminPath)) {
        Write-Host "Error: NWAdmin.exe not found at '$nwadminPath'. Please update the path." -ForegroundColor Red
        return
    }

# Execute nwadmin to get the raw workflow list
$foundWorkflows = & $nwadminPath -o FindWorkflows

#Core Logic
$workflowInventory = @()
$currentSite = ""
$currentList = ""
# Parse the raw output line by line
foreach ($line in $foundWorkflows) {
    if ($line.StartsWith("Active at ")) {
        $currentSite = $line.Replace("Active at ", "").Trim()
    }
    elseif ($line.StartsWith("-- ")) {
        # This regex handles both list names and workflow names, so we need to exclude the latter
        if (-not $line.StartsWith("---- ")) {
             $currentList = $line.Replace("-- ", "").Trim()
        }
    }
    elseif ($line.StartsWith("---- ")) {
        $workflowName = $line.Replace("---- ", "").Trim()

        # Determine workflow type based on list name
        $workflowType = 'List'
        if ($currentList -eq "Site Workflow") { $workflowType = 'Site' }
        if ($currentList -eq "Reusable workflow template") { $workflowType = 'Reusable' }
        if ($currentList -eq "Site collection reusable workflow template") { $workflowType = 'GloballyReusable' }

        # Create a structured object for the workflow
        $workflowObject =@{
            SiteUrl       = $currentSite
            ListName      = $currentList
            WorkflowName  = $workflowName
            WorkflowType  = $workflowType
        }
        $workflowInventory += $workflowObject
    }
}

# Export the inventory to a CSV file
    $workflowInventory | Export-Csv -Path $outputCsvPath -NoTypeInformation -Force

Write-Host "`n`nDiscovery complete. Inventory saved to '$outputCsvPath'" -F Green
Write-Host "Total workflows found: $($workflowInventory.Count)"
