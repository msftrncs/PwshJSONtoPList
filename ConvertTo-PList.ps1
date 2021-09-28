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
.PARAMETER EnumsAsStrings
    A switch that specifies an alternate serialization option that converts all enumerations to their string representations.
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

    [switch]$IndentFirstItem,

    [switch]$EnumsAsStrings,

    [ValidateRange(0,1000)]
    [uint32]$FormatDataInlineMaxLength,

    [ValidateRange(0,1000)]
    [uint32]$FormatDataWrapMaxLength = 44,

    [switch]$FormatDataWrappedNoIndent
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

    function writeObject ($item, [string]$indention, [int32]$level) {
        # write a property object

        function writeProperty ([string]$name, $item) {
            # write a dictionary key and its value

            # write out key name, if one was supplied
            if ($name) {
                "$indention$Indent<key>$($name | writeXMLcontent)</key>"
            } else {
                # no key name was supplied
                "$indention$Indent<key/>"
            }
            # write the property value, which could be an object
            writeObject $item $indention$Indent ($level + 1)
        }

        if (($item -is [string]) -or ($item -is [char]) -or ($EnumsAsStrings -and $item -is [enum])) {
            # handle strings, characters, or enums
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
                    "<integer>$(if ($item -isnot [enum]) { $item } else { $item.value__ })</integer>"
                }
            )"
        } elseif ($item -is [byte[]]) {
            # handle an array of bytes, encode as BASE64 string, write as DATA block
            # use REGEX to split out the string in to 44 character chunks properly indented
            $itemData = [convert]::ToBase64String($item)
            if (!$itemData -or $FormatDataInlineMaxLengthIsPresent -and ($FormatDataInlineMaxLength -eq 0 -or $itemData.Length -le $FormatDataInlineMaxLength)) {
                "$indention<data>$itemData</data>"    
            } else {
                "$indention<data>"
                $DataWrapperRegex.Matches($itemData).Value.ForEach({ "$indention$(if (!$FormatDataWrappedNoIndent) { $Indent })$_" })
                "$indention</data>"
            }
        } elseif ($level -le $Depth) {
            if ($item -is [array] -or $item -is [Collections.IList]) {
                # handle arrays
                if (,$item) {
                    "$indention<array>"
                    # iterate through the items in the array
                    foreach ($subItem in $item) {
                        writeObject $subItem $indention$Indent ($level + 1)
                    }
                    "$indention</array>"
                } else {
                    "$indention<array/>" # empty object
                }
            } elseif ($item -and $(if($item -is [Collections.IDictionary]) { $item.get_Keys().Count } else { @($item.psobject.get_Properties()).Count} ) -gt 0) {
                # handle objects by recursing with writeProperty
                "$indention<dict>"
                # iterate through the items
                if ($item-is [Collections.IDictionary]) {
                    # process what we assume is a hashtable object
                    foreach ($key in $item.Keys) {
                        writeProperty $key $item[$key]
                    }
                } else {
                    # process a custom object's properties
                    foreach ($property in $item.psobject.get_Properties()) {
                        writeProperty $property.Name $property.Value
                    }
                }
                "$indention</dict>"
            } else {
                "$indention<dict/>" # empty object
            }
        } else {
            # object has reached maximum depth, cast it out as a string
            writeObject "$item" $indention $level
        }
    }

    $(
        $FormatDataInlineMaxLengthIsPresent = $PSBoundParameters.ContainsKey('FormatDataInlineMaxLength')
        $DataWrapperRegex = [regex]".{1,$(if ($FormatDataWrapMaxLength -gt 0) {$FormatDataWrapMaxLength})}"

        # write the PList Header
        '<?xml version="1.0"' + $(if ($StateEncodingAs) { ' encoding="' + ($StateEncodingAs | writeXMLvalue) + '"' }) + '?>'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
        '<plist version="1.0">'

        # start writing the property list, the property list should be an object, and starts at base level
        writeObject $(
                # we need to determine where our input is coming from, pipeline or parameter argument.
                if ($input -is [array] -and $input.Length -ne 0) {
                    $input # input from pipeline
                } else {
                    $PropertyList # input from parameter argument
                }
            ) $(if ($IndentFirstItem) { $Indent } else { '' }) 0

        # end the PList document
        '</plist>'
    ) -join $(if (-not $IsCoreCLR -or $IsWindows) { "`r`n" } else { "`n" })
}
