# attempt to convert a JSON textmate language file back to PLIST tmLanguage file

# define a function to create a plist document, trying to keep it as generic as possible
function ConvertTo-PList ($PropertyList) {
    # write out a PList document based on the property list supplied

    function writeXMLcontent ([string]$value) {
        # write an escaped XML value
        # the intention of making this a function, is a single place to change the encoding function used
        [System.Security.SecurityElement]::escape($value)
    }

    function writeproperty ([string]$name, $item, [string]$indent) {
        # writing the property may require recursively breaking down the objects based on their type
        # name of the property is option, but that is only intended for the first property object

        function writevalue ($item, [string]$indent) {
            # write a property value, recurse non-string type objects back to writeproperty

            if ($item -is [string]) {
                # handle strings
                "$indent<string>$(writeXMLcontent($item))</string>"
            }
            else {
                # handle objects by recursing with writeproperty
                "$indent<dict>"
                foreach ($property in ([PSCustomObject]$item).psobject.Properties) {
                    writeproperty $property.Name $property.Value "$indent`t"
                }
                "$indent</dict>"
            }
        }

        # write out key name, if one was supplied
        if ($name) {
            "$indent<key>$(writeXMLcontent($name))</key>"
        }
        if ($item -is [array]) {
            # handle arrays
            "$indent<array>"
            foreach ($subitem in $item) {
                writevalue $subitem "$indent`t"
            }
            "$indent</array>"
        }
        else {
            Writevalue $item $indent
        }
    }

    # write the PList Header
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    '<plist version="1.0">'

    # start writing the property list, the property list should be an object, has no name
    writeproperty $null $PropertyList ""

    # end the PList document
    "</plist>"
}

<# this lists out the first level of properties to create the PList document from, and also gives the output order of the first level.
$FirstLevelObjects = @(
    'name'
    'patterns'
    'repository'
    'scopeName'
) #>

# from here on, we're converting the PowerShell.tmLanguage.JSON file to PLIST with hardcoded conversion requirements

# start by reading in the file through ConvertFrom-JSON
$grammer_json = Get-Content powershell.tmlanguage.json | ConvertFrom-Json

# write the PList document from a custom made object, supplying some data missing from the JSON file, ignoring some JSON objects
# and reordering the items that remain.
ConvertTo-Plist ([ordered]@{
        'fileTypes'                                          = ([string[]]$('ps1', 'psm1', 'psd1'))
        $grammer_json.psobject.Properties['name'].Name       = $grammer_json.psobject.Properties['name'].Value
        $grammer_json.psobject.Properties['patterns'].Name   = $grammer_json.psobject.Properties['patterns'].Value
        $grammer_json.psobject.Properties['repository'].Name = $grammer_json.psobject.Properties['repository'].Value
        $grammer_json.psobject.Properties['scopeName'].Name  = $grammer_json.psobject.Properties['scopeName'].Value
        'uuid'                                               = 'f8f5ffb0-503e-11df-9879-0800200c9a66'
    })
