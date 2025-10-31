<#
Script 2: Bulk Export Nintex Workflows
Description:
    This script reads the inventory CSV created by Script 1 and exports each workflow's.nwf definition file using the Nintex web service.
Prerequisites:
    Original inventory CSV file
    Credentials with sufficient permissions.
#>


# --- CONFIGURATION ---
    $inventoryCsvPath = "C:\Temp\NintexWorkflowInventory.csv"
    $exportBasePath = "C:\Temp\NintexExport"
    $nwadminPath = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN\NWAdmin.exe"
# ---------------------


# --- Import the workflow inventory ---
    if (-not (Test-Path $inventoryCsvPath))
    {
        Write-Host "Error: Inventory file not found at '$inventoryCsvPath'." -ForegroundColor Red
        return
    }
    $workflowsToExport = Import-Csv -Path $inventoryCsvPath
# ---------------------




Write-Host "`n`nStarting bulk export of $($workflowsToExport.Count) workflows..." -F Magenta
$count = 0
foreach ($workflow in $workflowsToExport) {
    $count ++
    #Changes $siteUrl if we've moved to a new site, in the case of multiple WFs per site.
    if($siteUrl -ne $workflow.SiteUrl)
    {
        $siteUrl = $workflow.SiteUrl
        Write-Host "`n$siteurl" -F Cyan
    }


    #Parameters.
    $listName = $workflow.ListName -replace "&amp;","&" -replace "&#39;","'" #Noticed some issues with special characters in list names. Add more here and in other scripts also if it becomes an issue.
    $workflowName = $workflow.WorkflowName
    $workflowType = $workflow.WorkflowType


    Write-Host "`t$count - $workflowName`t- " -NoNewLine


    # Sanitize parts of the path to be file-system friendly
    $safeSitePath = $siteUrl -replace "http://", "" -replace "https://", "" -replace "[:/]", "_"
    $safeListPath = $listName -replace "[:/]", "_"
    $safeWorkflowName = $workflowName -replace "[:/]", "_"


    # Create a structured output directory
    $outputDir = Join-Path -Path $exportBasePath -ChildPath (Join-Path -Path $safeSitePath -ChildPath $safeListPath)
    if (-not (Test-Path $outputDir))
    {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    $outputFile = Join-Path -Path $outputDir -ChildPath "$($safeWorkflowName).nwf"


    try
    {
        #Export Workflow using NWAdmin.exe -o ExportWorkflow
        & $nwadminPath -o ExportWorkflow -SiteUrl $siteUrl -list $listName -workflowname $workflowName -filename $outputFile -workflowtype $workflowType
    }
    catch
    {
        Write-Host "ERROR: $($_.Exception.Message)" -F Red
    }
}


Write-Host "`nBULK EXPORT PROCESS COMPLETE" -F Green  



