# Script 3: Modify.nwf Files with URL Replacements
    # Description: This script recursively finds all.nwf files in the export directory, loads each as an XML document, and replaces all occurrences of the old string to new string. 


# --- CONFIGURATION ---
    $exportBasePath = "C:\Temp\NintexExport"
    $modifiedBasePath = "C:\Temp\NintexModified"


    $FindAndReplace = @()
    $FindAndReplace += [PSCustomObject]@{
        Find = "https://oldurl.domain.com"
        Replace = "https://newurl.domain.com"
    }
    $FindAndReplace += [PSCustomObject]@{
        Find = "https://oldurl2.domain.com"
        Replace = "https://newurl2.domain.com"
    }
    $FindAndReplace += [PSCustomObject]@{
        Find = "oldemail@domain.com"
        Replace = "newemail@domain.com"
    }
# ---------------------


# Get all exported.nwf files
    $exportedFiles = Get-ChildItem -Path $exportBasePath -Recurse -Filter "*.nwf"




Write-Host "`nStarting modification of $($exportedFiles.Count) '.nwf' files..." -F Magenta
$count = 0
foreach ($file in $exportedFiles) {
    $count ++
    Write-Host "`t$count - $($file.name)`t- " -NoNewline


    try {
        # Load the.nwf file
        $originalcontent = $NULL
        $originalcontent = $file | get-content
        $modifiedcontent = $originalcontent


        #Go through the items in Find & Replace.
        foreach($Item in $FindAndReplace)
        {
            foreach($Line in $modifiedcontent)
            {
                if($Line -like "*$($Item.Find)*")
                {
                    $ActionRequired = $TRUE
                    break
                }
            }


            if($ActionRequired)
            {
                $modifiedcontent = $modifiedcontent -replace $item.Find,$item.Replace
                $ActionRequired = $NULL #Resets for next item in FindAndReplace
            }


        }


        # Create the corresponding output path in the 'modified' directory
        $modifiedFilePath = $file.FullName.Replace($exportBasePath, $modifiedBasePath)
        $modifiedFileDir = Split-Path -Path $modifiedFilePath -Parent


        #Creates directory for modified file if it doesn't exist.
        if (-not (Test-Path $modifiedFileDir)) {
            New-Item -Path $modifiedFileDir -ItemType Directory -Force | Out-Null
        }


        # Save the modified content to the new location
        $ModItem = New-Item -Path $modifiedFilePath -ItemType File -Force
        $ModItem | Set-Content -Value $modifiedcontent -Force
        Write-Host "Saved modified file to '$exportbasePath'" -ForegroundColor Yellow


    }
    catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
        pause
    }
}


Write-Host "`n`nMODIFICATION PROCESS COMPLETE" -F Green









