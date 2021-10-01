# PwshJSONtoPList - ConvertTo-PList

Convert a PowerShell object to an XML PList.

Originally intended for the conversion of JSON based tmLanguage grammar definitions to the formal tmLanguage PLIST format.

Example based on JSON tmLanguage file.

```PowerShell
Get-Content "powershell.tmlanguage.json" | ConvertFrom-Json |
    ConvertTo-Plist -Indent "`t" -StateEncodingAs 'UTF-8' |
    Set-Content 'out\PowerShellSyntax.tmLanguage' -Encoding 'UTF8'
```

```PowerShell
$grammar_json = Get-Content "powershell.tmlanguage.json" | ConvertFrom-Json
ConvertTo-Plist $grammar_json -Indent "`t" -StateEncodingAs 'UTF-8' |
    Set-Content 'out\PowerShellSyntax.tmLanguage' -Encoding 'UTF8'
```

```PowerShell
[xml]$grammar_xml = Get-Content "powershell.tmlanguage.json" | ConvertFrom-Json |
    ConvertTo-Plist -Indent "`t" -StateEncodingAs $null 
```

### Parameters

#### PropertyList

The PowerShell object which possesses the items for the PLIST.  This can be any object that can be represented as a PSCustomObject.  This parameter may be received from the pipeline.

#### Compress

Omits white space and indented formatting in the output string.  Ignores all further indenting and formatting related parameters.

#### Indent

Specifies the indentation to use when generating the XML output.  The default is ```"`t"``` (tab), but other usual options are `''` (none), `'    '` (4 spaces), but otherwise any string is accepted, and no escaping is performed.

#### StateEncodingAs

Specifies the encoding to state in the XML header.  This does not actually set the encoding as this function does not directly produce encoded output.  See the examples above.  The default is 'UTF-8'.  Specify `$null` to remove the `encoding` attribute from the header.

#### Depth

Specifies the maximum depth of recursion permitted for the input property list object.

#### IndentFirstItem

A switch that specifies that the first item level of the PLIST XML is to be indented.  Most PLIST files do not have the first item level indented, but a formal XML writer would normally do this.

#### EnumsAsStrings

A switch that specifies an alternate serialization option that converts all enumerations to their string representations.

#### FormatDataInlineMaxLength

Maximum encoded `<data>` length for keeping value inline, if unspecified, all data will be nested and wrapped, if 0, all data will be inline.

#### FormatDataWrapMaxLength

Maximum encoded `<data>` length for each nested wrapped line once exceeding FormatDataInlineMaxLength, or 0 for all data to be on a single nested line.

#### FormatDataWrappedNoIndent

A switch to prevent the indenting of `<data>` content when nested/wrapped on separate lines.

### Output

The output of this function is a single string (`[string]`).  Use Out-File or Set-Content and be sure to assign the correct encoding.  You may also use the `[xml]` accelerator when assigning the output to a variable, and then use XML cmdlets or tools on the result.

Note:
- Escapes only '&lt;', '&amp;' and '&gt;'.
- The PList XML generator should be complete, with regard to item data type handling.
