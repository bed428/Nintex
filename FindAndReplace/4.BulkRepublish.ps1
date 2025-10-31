<#
Script 4/4: Bulk Republish Modified Nintex Workflows
Description:
    This script finds all modified.nwf files, reads the original inventory to get metadata, and republishes each workflow using the Nintex web service.
Prerequisites:
    original inventory CSV  
    Modified.nwf files
    Admin credentials
#>
$start = get-date
Write-Host "`n`nStart: $Start" ;


# --- CONFIGURATION ---
    $nwadminPath = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN\NWAdmin.exe"
    $inventoryCsvPath = "C:\Temp\NintexWorkflowInventory.csv"
    $modifiedBasePath = "C:\Temp\NintexModified"
    $Credential = Get-Credential -Message "`n`n" -UserName "domain\runasaccount"
    $NetCredential = $Credential.GetNetworkCredential()
# ---------------------


# --- Import the original workflow inventory ---
    if (-not (Test-Path $inventoryCsvPath)) 
    {
        Write-Host "Error: Inventory file not found at '$inventoryCsvPath'." -ForegroundColor Red
        return
    }
    $workflowInventory = Import-Csv -Path $inventoryCsvPath
# ---------------------


Write-Host "`n`nStarting bulk republishing of workflows..." -F Magenta
$n = 0
foreach ($workflow in $workflowInventory) 
{
    $n ++


    $siteUrl = $workflow.SiteUrl
    $listName = $workflow.ListName -replace "&amp;","&" -replace "&#39;","'"
    $workflowName = $workflow.WorkflowName


    # Reconstruct the path to the modified.nwf file
    $safeSitePath = $siteUrl -replace "http://", "" -replace "https://", "" -replace "[:/]", "_"
    $safeListPath = $listName -replace "[:/]", "_"
    $safeWorkflowName = $workflowName -replace "[:/]", "_"
    $modifiedFile = Join-Path -Path $modifiedBasePath -ChildPath (Join-Path -Path $safeSitePath -ChildPath (Join-Path -Path $safeListPath -ChildPath "$($safeWorkflowName).nwf"))


    #Skip if $modifiedFile is not found.
    if (-not (Test-Path $modifiedFile)) {
        Write-Host "`t$n- '$siteUrl'`t- '$workflowName'`t - SKIPPED: No Modified File Found" -ForegroundColor Yellow
        continue
    }


    Write-Host "`t$n - '$siteUrl'`t- '$workflowName'`t - " -NoNewline
    #DeployWorkflowReference: https://help.nintex.com/en-US/nintexSE/current/sp2019/NWAdmin/DeployWorkflow.htm
    try 
    {
        if($workflow.WorkflowType -eq "Site")
        {
            $Result = & $nwadminPath -o DeployWorkflow -workflowName $workflowName -nwfFile $modifiedFile -siteUrl $siteUrl -overwrite -username $NetCredential.UserName -password $NetCredential.Password -domain $NetCredential.Domain
        }
        elseif($workflow.WorkflowType -eq "List")
        {
            $Result = & $nwadminPath -o DeployWorkflow -workflowName $workflowName -nwfFile $modifiedFile -siteUrl $siteUrl -targetList $listName -overwrite -username $NetCredential.UserName -password $NetCredential.Password -domain $NetCredential.Domain
        }
        elseif($workflow.WorkflowType -eq "GloballyReusable")
        {
            $Result = & $nwadminPath -o DeployWorkflow -workflowName $workflowName -nwfFile $modifiedFile -siteUrl $siteUrl -overwrite -username $NetCredential.UserName -password $NetCredential.Password -domain $NetCredential.Domain
        }
        else
        {
            Write-Host -F Red "ERROR: Unrecognized Workflow Type"
        }


        if($Result -eq "Workflow Published.")
        {
            Write-Host -F Green "Workflow Published"
        }
        else
        {
            Write-Host -F Red "Unexpected Result: $Result"
            pause
        }
    }
    catch {
        Write-Host "  -> Republish failed with an error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
$Finish = get-date




Write-Host "`n`n ---------------------
BULK REPUBLISHING PROCESS COMPLETE
    Start:   $Start
    Finish:  $Finish
    Elapsed: $(($Finish - $Start).ToString())
    Items:   $($workflowInventory.Count)
 ---------------------" -F Green

