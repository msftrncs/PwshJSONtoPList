# PwshJSONtoPList

Powershell function to convert PowerShell.tmLanguage.JSON file to PList.

Within it is a fairly complete PList generator function.

Its intention is to convert the VS Code PowerShell tmLanguage language syntax file back to PList format after edited as a JSON file.

Note:
- SecurityElement.encode is used, so a variety of characters have been escaped.
- Only string data values are supported by the PList converter, I am unaware if any other data types are needed.
