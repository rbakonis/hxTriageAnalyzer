# Prompt for triage file
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.ShowDialog() | Out-Null
$srcFile = $FileBrowser.filename

Write-Host "Begin processing $srcFile"

# Copy/extract triage
$docRoot = Split-Path $srcFile
$docName = (Split-Path $srcFile -Leaf).split('.')[0]
$tempFile = "$docRoot\$docName.zip"
$tempDest = "$docRoot\$docName"


try{
    Copy-Item -Path $srcFile -Destination $tempFile -Force
    Expand-Archive $tempFile -Force -DestinationPath $tempDest
}
catch{
    Write-Host "Failed to copy or extract triage bundle. Error: $($Error[0].Exception)"
    exit 1   
}

# Find event dump in extract
foreach($file in gci $tempDest | sort length -Descending){
    if(gc $file.versioninfo.filename | select -First 10 | select-string "<eventItem"){
        $eventDB = $file.versioninfo.filename
        Write-Host "Event XML found. Parsing file: $eventDB"
        break
    }
}

# Parse XML event data
if($eventDB){
    try{
        $tmp= [xml]''
        $tmp.Load($eventDB)
    }
    catch{
        Write-Host "Failed to parse Event XML. Confirm file consistency. Error: $($Error[0].Exception)"
    }
}
else{
    Write-Host "Event DB not found in triage bundle. Acquire another bundle."
    exit 1
}

# Extract unique event types
$itemTypes = $tmp.itemList.eventItem.eventtype | sort -Unique

foreach($type in $itemTypes){
    $group = $tmp.itemlist.eventItem | ? {$_.eventType -eq $type}
    $percent = [math]::Round(($group.count/$tmp.itemlist.eventItem.count)*100,0)
    Write-Host "-----------------------------------------------"
    Write-Host "Processing Event Type: $type" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------"
    Write-Host "Total items of type, $($type): $($group.Count)"
    Write-Host "Percentage of total events in Triage: $percent"    
    $processes = (($group.details.detail | ? {$_.name -eq "process"}).value | sort | Group-Object) | sort Count -Descending | select Count, Name -First 10
    if($processes){
        Write-Host "_______________________________________________"
        Write-Host "`r`nTop 10 Processes for $($type):`r`n"
        Write-Host "Count    Name"
        Write-Host "-----    ----"
        foreach($proc in $processes){
            if (($path = (($group | ? {$_.details.detail.value -eq $proc.Name}).details.detail | ? {$_.name -eq "processPath"}).value | sort -Unique).count -eq 1){
                $i = ".........".Substring($proc.count.ToString().length)
                Write-Host "$($proc.Count)$($i)$($path)\$($proc.name)"
            }
            else{
                Write-Host "         [Multiple paths for process: $($proc.Name)]" -ForegroundColor Cyan
                $i = ".........".Substring($proc.count.ToString().length)
                Write-Host "$($proc.Count)$($i)$($path)\$($proc.name)"
            }
        } 
        Write-Host "`r`n"
    }

    if($type -eq "ipv4NetworkEvent"){
        Write-Host "_______________________________________________"
        Write-Host "IPv4 Top Talker Analysis`r`n"
        $remoteConnections = (($group.details.detail | ? {$_.name -eq "remoteIP"}).value | ? {$_ -ne "127.0.0.1"} | sort | group-object) | sort Count -Descending | select Count,Name -First 10
        foreach($row in $remoteConnections){
            Write-Host "Processes connecting to $($row.name):`r`n"
            $results = ($group | ? {$_.details.detail.name -eq "remoteIP" -and $_.details.detail.value -eq $row.name})
            $processes = ($results.details.detail | ? {$_.name -eq "process"}).value
            $processes = $processes | sort | Group-Object | sort Count -Descending | select name,count
            Write-Host "Count    Name"
            Write-Host "-----    ----"
            foreach($proc in $processes){
                $i = ".........".Substring($proc.count.ToString().length)
                Write-Host "$($proc.Count)$i$($proc.name)"
            }
            write-host "`r`n" 
            
        }
    }

    write-Host "Done Processing $type`r`n"
}

