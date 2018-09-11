# attempt to convert a JSON textmate language file back to PLIST tmLanguage file

# parameters to the script - needs work to support multiple paths  (WIP)
[CmdletBinding()]
Param(

    # Specifies a path to one or more locations. Wildcards are permitted.
    [Parameter(Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string[]]$Path,

    [Parameter(Mandatory = $false,
        Position = 1,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $false,
        HelpMessage = "Indention pattern.")]
    [ValidateNotNull()]
    [string]$Indent = "`t"

)

# define a function to create a plist document, trying to keep it as generic as possible
function ConvertTo-PList ($PropertyList, [string]$indent) {
    # write out a PList document based on the property list supplied
    # $PropertyList is an object containing the entire property list tree.  Hash tables are supported.
    # $indent is a string representing the indentation to use.
    #   Typically use "`t" or "  ".

    function writeXMLcontent ([string]$value) {
        # write an escaped XML value, the only characters requiring escape in XML character content
        # are &lt; and &amp;, but we'll escape &gt; as well for good habit.
        # the purpose of making this a function, is a single place to change the escaping function used
        $value -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
    }

    function writeproperty ([string]$name, $item, [string]$level) {
        # writing the property may require recursively breaking down the objects based on their type
        # name of the property is optional, but that is only intended for the first property object

        function writevalue ($item, [string]$level) {
            # write a property value, recurse non-string type objects back to writeproperty

            if (($item -is [string]) -or ($item -is [char])) {
                # handle strings or characters
                "$level<string>$(writeXMLcontent($item))</string>"
            }
            elseif ($item -is [boolean]) {
                # handle boolean type
                "$level$(
                    if ($item) {
                        "<true/>"
                    }
                    else {
                        "<false/>"
                    }
                )"
            }
            elseif ($item -is [ValueType]) {
                # handle numeric types
                "$level$(
                    if (($item -is [single]) -or ($item -is [double]) -or ($item -is [decimal])) {
                        # floating point or decimal numeric types
                        "<real>$item</real>"
                    }
                    elseif ($item -is [datetime]) {
                        # date and time numeric type
                        "<date>$(writeXMLcontent($item))</date>"
                    }
                    else {
                        # interger numeric types
                        "<integer>$item</integer>"
                    }
                )"
            }
            else {
                # handle objects by recursing with writeproperty
                "$level<dict>"
                # iterate through the items (force to a PSCustomObject for consistency)
                foreach ($property in ([PSCustomObject]$item).psobject.Properties) {
                    writeproperty $property.Name $property.Value "$level$indent"
                }
                "$level</dict>"
            }
        }

        # write out key name, if one was supplied
        if ($name) {
            "$level<key>$(writeXMLcontent($name))</key>"
        }
        if ($item -is [array]) {
            # handle arrays
            "$level<array>"
            if ($item -is [byte[]]) {
                # handle an array of bytes, encode as BASE64 string, store as DATA block
                # use REGEX to split out the string in to 44 character chunks properly indented
                "$level$indent<data>"
                [regex]::Matches([convert]::ToBase64String($item), '(.{1,44})').value.foreach( {"$level$indent$_"} )
                "$level$indent</data>"
            }
            else {
                # iterate through the items in the array
                foreach ($subitem in $item) {
                    writevalue $subitem "$level$indent"
                }
            }
            "$level</array>"
        }
        else {
            # handle a single object
            Writevalue $item $level
        }
    }

    # write the PList Header
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    '<plist version="1.0">'

    # start writing the property list, the property list should be an object, has no name, and starts at base level
    writeproperty $null $PropertyList ""

    # end the PList document
    '</plist>'
}

<# this lists out the first level of properties to create the PList document from, and also gives the output order of the first level.
$FirstLevelObjects = @(
    'name'
    'patterns'
    'repository'
    'scopeName'
) #>

# from here on, we're converting the PowerShell.tmLanguage.JSON file to PLIST with hardcoded conversion requirements
foreach ($file in $Path) {

    # start by reading in the file through ConvertFrom-JSON
    $grammer_json = Get-Content $file | ConvertFrom-Json

    # write the PList document from a custom made object, supplying some data missing from the JSON file, ignoring some JSON objects
    # and reordering the items that remain.
    ConvertTo-Plist ([ordered]@{
            'fileTypes'                                          = ([string[]]$('ps1', 'psm1', 'psd1'))
            $grammer_json.psobject.Properties['name'].Name       = $grammer_json.psobject.Properties['name'].Value
            $grammer_json.psobject.Properties['patterns'].Name   = $grammer_json.psobject.Properties['patterns'].Value
            $grammer_json.psobject.Properties['repository'].Name = $grammer_json.psobject.Properties['repository'].Value
            $grammer_json.psobject.Properties['scopeName'].Name  = $grammer_json.psobject.Properties['scopeName'].Value
            'uuid'                                               = 'f8f5ffb0-503e-11df-9879-0800200c9a66'
        }) $Indent
}
