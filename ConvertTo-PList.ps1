<#
.SYNOPSIS
    Convert a PowerShell object to an XML Plist represented in a string.
.DESCRIPTION
    Converts a PowerShell object to an XML PList (property list) notation as a string.
.PARAMETER PropertyList
    The input PowerShell object to be represented in an XML PList notation.  This parameter may be received from the pipeline.
.PARAMETER Indent
    Specifies a string value to be used for each level of the indention within the XML document.
.PARAMETER StateEncodingAs
    Specifies a string value to be stated as the value of the `encoding` attribute of the XML document header.  This does not actually set the encoding.
.PARAMETER Depth
    Specifies the maximum depth of recursion permitted for the input property list object.
.PARAMETER IndentFirstItem
    A switch causing the first level of objects to be indented as per normal XML practices.
.EXAMPLE
    $grammar_json | ConvertTo-Plist -Indent `t -StateEncodingAs UTF-8 | Set-Content out\PowerShellSyntax.tmLanguage -Encoding UTF8
.INPUTS
    [object] - containing the PList as conventional PowerShell object types, hashtables, arrays, strings, numeric values, and byte arrays.
.OUTPUTS
    [string] - the input object returned in an XML PList notation.
.NOTES
    Script / Function / Class assembled by Carl Morris, Morris Softronics, Hooper, NE, USA
    Initial release - Aug 18, 2018
.LINK
    https://github.com/msftrncs/PwshJSONtoPList/
.FUNCTIONALITY
    data format conversion
#>
function ConvertTo-PList
(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [AllowEmptyCollection()]
    [AllowNull()]
    [AllowEmptyString()]
    [object]$PropertyList,

    [PSDefaultValue(Help = 'Tab')]
    [string]$Indent = "`t",

    [string]$StateEncodingAs = 'UTF-8',

    [ValidateRange(1, 100)]
    [int32]$Depth = 2,

    [switch]$IndentFirstItem
) {
    # write out a PList document based on the property list supplied
    # $PropertyList is an object containing the entire property list tree.  Hash tables are supported.
    # $Indent is a string representing the indentation to use.
    #   Typically use "`t" or "  ".
    # $StateEncodingAs is a string to supply in the XML header that represents the encoding XML will
    # be represented as in the final file

    filter writeXMLcontent {
        # write an escaped XML content, the only characters requiring escape in XML character content
        # are &lt; and &amp;, but we'll escape &gt; as well for good habit.
        # the purpose of making this a function, is a single place to change the escaping function used
        $_ -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
    }

    filter writeXMLvalue {
        # write an escaped XML value, the only characters requiring escape in XML attribute values
        # are &lt; and &amp; and &quo, but we'll escape &gt; as well for good habit.
        # the purpose of making this a function, is a single place to change the escaping function used
        ($_ | writeXMLcontent) -replace '"', '&quot;'
    }

    function writeproperty ([string]$name, $item, [string]$indention, [int32]$level) {
        # writing the property may require recursively breaking down the objects based on their type
        # name of the property is optional, but that is only intended for the first property object

        function writevalue ($item, [string]$indention) {
            # write a property value, recurse non-string type objects back to writeproperty

            if (($item -is [string]) -or ($item -is [char])) {
                # handle strings or characters
                "$indention<string>$($item | writeXMLcontent)</string>"
            } elseif ($item -is [boolean]) {
                # handle boolean type
                "$indention$(
                    if ($item) {
                        "<true/>"
                    } else {
                        "<false/>"
                    }
                )"
            } elseif ($item -is [ValueType]) {
                # handle numeric types
                "$indention$(
                    if (($item -is [single]) -or ($item -is [double]) -or ($item -is [decimal])) {
                        # floating point or decimal numeric types
                        "<real>$item</real>"
                    } elseif ($item -is [datetime]) {
                        # date and time numeric type
                        "<date>$($item.ToString('o') | writeXMLcontent)</date>"
                    } else {
                        # interger numeric types
                        "<integer>$item</integer>"
                    }
                )"
            } elseif ($level -le $Depth) {
                # handle objects by recursing with writeproperty
                "$indention<dict>"
                # iterate through the items
                if ($item -is [pscustomobject]) {
                    # process a custom object's properties
                    foreach ($property in $item.psobject.Properties) {
                        writeproperty $property.Name $property.Value "$indention$Indent" ($level + 1)
                    }
                } else {
                    # process what we assume is a hashtable object
                    foreach ($key in $item.Keys) {
                        writeproperty $key $item[$key] "$indention$Indent" ($level + 1)
                    }
                }
                "$indention</dict>"
            } else {
                # object has reached maximum depth, cast it out as a string
                writevalue "$item" "$indention"
            }
        }

        # write out key name, if one was supplied
        if ($name) {
            "$indention<key>$($name | writeXMLcontent)</key>"
        }
        if ($item -is [array]) {
            # handle arrays
            if ($item -is [byte[]]) {
                # handle an array of bytes, encode as BASE64 string, write as DATA block
                # use REGEX to split out the string in to 44 character chunks properly indented
                "$indention<data>"
                [regex]::Matches([convert]::ToBase64String($item), '(.{1,44})').value.foreach({ "$indention$Indent$_" })
                "$indention</data>"
            } elseif ($level -le $Depth) {
                "$indention<array>"
                # iterate through the items in the array
                foreach ($subitem in $item) {
                    writeproperty '' $subitem "$indention$Indent" ($level + 1)
                }
                "$indention</array>"
            } else {
                # object has reached maximum depth, cast it out as a string
                writevalue "$item" "$indention"
            }
        } else {
            # handle a single object
            Writevalue $item $indention
        }
    }

    $(
        # write the PList Header
        '<?xml version="1.0"' + $(if ($StateEncodingAs) { ' encoding="' + ($StateEncodingAs | writeXMLvalue) + '"' }) + '?>'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
        '<plist version="1.0">'

        # start writing the property list, the property list should be an object, has no name, and starts at base level
        writeproperty '' $PropertyList $(if ($IndentFirstItem.IsPresent) { $Indent } else { '' }) 0

        # end the PList document
        '</plist>'
    ) -join $(if (-not $IsCoreCLR -or $IsWindows) { "`r`n" } else { "`n" })
}
