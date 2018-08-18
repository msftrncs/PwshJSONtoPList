# attempt to convert a JSON textmate language file back to PLIST tmLanguage file

function make-plist ([string]$name, $item, [bool]$isArray, [string]$indent) {
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
                foreach ($property in $subitem.psobject.properties) {
                    make-plist $property.Name $property.Value ($property.Value -is [array]) "$indent`t`t" 
                }
                "$indent`t</dict>"
            }
        }
        "$indent</array>"
    }
    elseif ($item -is [System.Management.Automation.PSCustomObject]) {
        # handle non array objects
        "$indent<dict>"
        foreach ($property in $item.psobject.properties) {
            make-plist $property.Name $property.Value ($property.Value -is [array]) "$indent`t" 
        }
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

# this lists out the first level of properties to create the PList document from, and also gives the output order of the first level.
$FirstLevelObjects = @(
    'name'
    'patterns'
    'repository'
    'scopeName'
)

# start by reading in the file through ConvertFrom-JSON
$grammer_json = Get-Content powershell.tmlanguage.json | ConvertFrom-Json

# write the PList header out
'<?xml version="1.0" encoding="UTF-8"?>'
'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
'<plist version="1.0">'
"<dict>" #technically this is the begining of the first level

# write out a fixed 'fileTypes' property.
make-plist "fileTypes" ([string[]]$('ps1', 'psm1', 'psd1')) $true "`t"

# only pass the first items if they match 'name', 'patterns', or 'repository', 'scopeName' (and in that order), the items will then recurse.
foreach ($key in $FirstLevelObjects) {
    if ($grammer_json.psobject.Properties[$key]) {
        make-plist $grammer_json.psobject.Properties[$key].Name $grammer_json.psobject.Properties[$key].Value ($grammer_json.psobject.Properties[$key].Value -is [array]) "`t" 
    }
}

# add the ?PowerShell? 'uuid'
make-plist "uuid" "f8f5ffb0-503e-11df-9879-0800200c9a66" $false "`t"

#end the first level, then end the PList document
"</dict>"
"</plist>"

# the PList file has now been written to stdout
