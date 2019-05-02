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

#### Indent

Specifies the indentation to use when generating the XML output.  The default is ```"`t"``` (tab), but other usual options are `''` (none), `'    '` (4 spaces), but otherwise any string is accepted, and no escaping is performed.

#### StateEncodingAs

Specifies the encoding to state in the XML header.  This does not actually set the encoding as this function does not directly produce encoded output.  See the examples above.  The default is 'UTF-8'.  Specify `$null` to remove the `encoding` attribute from the header.

#### IndentFirstItem

A switch that specifies that the first item level of the PLIST XML is to be indented.  Most PLIST files do not have the first item level indented, but a formal XML writer would normally do this.

### Output

The output of this function is a single string (`[string]`).  Use Out-File or Set-Content and be sure to assign the correct encoding.  You may also use the `[xml]` accelerator when assigning the output to a variable, and then use XML cmdlets or tools on the result.

Note:
- Escapes only '&lt;', '&amp;' and '&gt;'.
- The PList XML generator should be complete, with regard to item data type handling.
- Objects that possess recursive backreferences (loops) will lock up the function.  There is no `-Depth` parameter yet.
