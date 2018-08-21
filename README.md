# PwshJSONtoPList

Powershell function to convert PowerShell.tmLanguage.JSON file to XML PList.

Within it is a fairly complete XML PList generator function.

Its intention is to convert the VS Code PowerShell tmLanguage language syntax file back to XML PList format after edited as a JSON file.

Note:
- SecurityElement.encode is used, so a variety of characters have been escaped.
- The PList XML generator is only known to be missing &lt;DATA&gt; field support.
- the indentation of the XML is adjustable.
- The XML document's encoding is hardset as 'encoding="UTF-8"', but might not match the actual output.
- The resulting XML is output to the stdout (console).
- The script has parameters for path to the .tmLanguage.JSON file, which accepts wildcards and arrays, but this is a Work In Progress.
