# attempt to convert a JSON textmate language file back to PLIST tmLanguage file

function make-plist ($name, $item, [bool]$isArray, [string]$indent) {
    # recursively break down the objects based on their type
    # single item array types get converted to non array types when passed, so this information has to be tracked via $isArray
    "$indent<key>$([System.Web.HttpUtility]::HtmlEncode($name))</key>"
    if ($isArray) {
        # handle most arrays or items that should have been arrays
        "$indent<array>"
        if ($item -is [string[]]) {
            # handle arrays of strings
            foreach ($subitem in $item) {
                "$indent`t<string>$([System.Web.HttpUtility]::HtmlEncode($subitem))</string>"
            }
        }
        else {
            # handle an array of objects
            foreach ($subitem in $item) {
                "$indent`t<dict>"
                $subitem | Get-Member -type noteproperty | ForEach-Object { make-plist $_.Name $(Invoke-Expression "`$subitem.$($_.Name)") $(Invoke-Expression "`$subitem.$($_.Name) -is [array]") "$indent`t`t" }
                "$indent`t</dict>"
            }
        }
        "$indent</array>"
    }
    elseif ($item -is [System.Management.Automation.PSCustomObject]) {
        # handle non array objects
        "$indent<dict>"
        $item | Get-Member -type noteproperty | ForEach-Object { make-plist $_.Name $(Invoke-Expression "`$item.$($_.Name)") $(Invoke-Expression "`$item.$($_.Name) -is [array]") "$indent`t" }
        "$indent</dict>"
    }
    elseif ($item -is [string] ) {
        # handle non array strings
        "$indent<string>$([System.Web.HttpUtility]::HtmlEncode($item))</string>"
    }
    else {
        throw "unhandled type $($item.gettype().Name)"
    }
}

$FirstLevelObjects = @(
    'name'
    'patterns'
    'repository'
)

# start by reading in the file through ConvertFrom-JSON
$grammer_json = Get-Content powershell.tmlanguage.json | ConvertFrom-Json

# write the PLIST header out
'<?xml version="1.0" encoding="UTF-8"?>'
'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
'<plist version="1.0">'
"<dict>" #technically this is the begining of the first level

# write out a fixed 'fileTypes' property.
make-plist "fileTypes" ([string[]]$('ps1', 'psm1', 'psd1')) $true "`t"

# only pass the first items if they match 'name', 'patterns', or 'repository', the items will recurse.
$grammer_json | Get-Member -type noteproperty | Where-Object Name -in $FirstLevelObjects | ForEach-Object { make-plist $_.Name $(Invoke-Expression "`$grammer_json.$($_.Name)") $(Invoke-Expression "`$grammer_json.$($_.Name) -is [array]") "`t" }

# the PList file has now been written to stdout
