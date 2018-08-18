# PwshJSONtoPList

Powershell function to convert JSON (or other PSObject) to PList.

Its intention is to convert tmLanguage language syntax files back to PList format after edited in JSON for VSCode.

The first versions may be hardcoded to convert a single input file.

Note:
PowerShell doesn't seem to keep the JSON order as it processes objects.

HtmlEncode was used, so a variety of characters have been escaped.

Only string data format is supported, I am unaware if any other data types are needed.
