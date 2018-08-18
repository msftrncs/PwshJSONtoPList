# attempt to convert a JSON textmate language file back to PLIST tmLanguage file

function make-plist ($name, $item, [bool]$isArray, $indent) {
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
        elseif ($item -is [System.Object[]]) {
            # handle an array of objects
            foreach ($subitem in $item) {
                "$indent`t<dict>"
                $subitem | get-member -type noteproperty | ForEach-Object { make-plist $_.name $(Invoke-Expression "`$subitem.$($_.name)") $(Invoke-Expression "`$subitem.$($_.name) -is [array]") "$indent`t`t" }
                "$indent`t</dict>"
            }
        }
        else {
            # handle the 'patterns' that come in as a single item array
            "$indent`t<dict>"
            $item | get-member -type noteproperty | ForEach-Object { make-plist $_.name $(Invoke-Expression "`$item.$($_.name)") $(Invoke-Expression "`$item.$($_.name) -is [array]") "$indent`t`t" }
            "$indent`t</dict>"
        }
        "$indent</array>"
    }
    elseif ($item -is [System.Management.Automation.PSCustomObject]) {
        # handle non array objects
        "$indent<dict>"
        $item | get-member -type noteproperty | ForEach-Object { make-plist $_.name $(Invoke-Expression "`$item.$($_.name)") $(Invoke-Expression "`$item.$($_.name) -is [array]") "$indent`t" }
        "$indent</dict>"
    }
    elseif ($item -is [string] ) {
        # handle non array strings
        "$indent<string>$([System.Web.HttpUtility]::HtmlEncode($item))</string>"
    }
    else {
        throw "unknown type $($item.gettype().name)"
    }
}

$FirstLevelObjects = @(
    'name'
    'patterns'
    'repository'
)



$grammer_json = get-content powershell.tmlanguage.json | convertfrom-json

#$grammer_json | get-member -type noteproperty | ForEach-Object {Write-Output "<key>$($_.name)</key><string>$($grammer_json | select-object -expandproperty $_.name)</string>"}

'<?xml version="1.0" encoding="UTF-8"?>'
'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
'<plist version="1.0">'
"<dict>"

make-plist "fileTypes" ([string[]]$('ps1', 'psm1', 'psd1')) $true "`t"

# only pass the first items if they match 'name', 'patterns', or 'repository'
#$grammer_json | get-member -type noteproperty | Where-Object Name -in $FirstLevelObjects | ForEach-Object { make-plist $_.name $(if ($_.name -eq 'patterns') {@($grammer_json | select-object -expandproperty $_.name)} ELSE {$grammer_json | select-object -expandproperty $_.name}) "`t" }

$grammer_json | get-member -type noteproperty | Where-Object Name -in $FirstLevelObjects | ForEach-Object { make-plist $_.name $(Invoke-Expression "`$grammer_json.$($_.name)") $(Invoke-Expression "`$grammer_json.$($_.name) -is [array]") "`t" }

