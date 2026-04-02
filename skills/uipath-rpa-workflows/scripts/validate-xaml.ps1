<#
.SYNOPSIS
    Pre-flight XAML validator for UiPath workflows.
    Catches structural issues that Studio reports with cryptic errors,
    and returns clear, actionable fix instructions as JSON.

.PARAMETER XamlPath
    Absolute or relative path to the .xaml file to validate.

.PARAMETER ProjectRoot
    Path to the UiPath project root (containing project.json).
    If omitted, walks up from XamlPath looking for project.json.

.OUTPUTS
    JSON array of findings. Empty array = all checks passed.
    Each finding: { rule, severity, message, fix, line }
#>
param(
    [Parameter(Mandatory)]
    [string]$XamlPath,

    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- helpers ---

function Out-Finding {
    param(
        [string]$Rule,
        [string]$Severity,  # error | warning
        [string]$Message,
        [string]$Fix,
        [int]$Line = 0
    )
    [PSCustomObject]@{
        rule     = $Rule
        severity = $Severity
        message  = $Message
        fix      = $Fix
        line     = $Line
    }
}

function Get-LineNumber {
    param([string]$Content, [string]$Search)
    $lines = $Content -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape($Search)) {
            return $i + 1
        }
    }
    return 0
}

# --- resolve paths ---

if (-not (Test-Path $XamlPath)) {
    ConvertTo-Json -InputObject @([PSCustomObject]@{
        rule     = 'file-not-found'
        severity = 'error'
        message  = "XAML file not found: $XamlPath"
        fix      = "Check the file path. Use absolute path or ensure CWD is correct."
        line     = 0
    }) -Depth 5
    exit 0
}

$XamlPath = (Resolve-Path $XamlPath).Path

# find project root
if (-not $ProjectRoot) {
    $dir = Split-Path $XamlPath -Parent
    while ($dir -and -not (Test-Path (Join-Path $dir 'project.json'))) {
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { $dir = $null; break }
        $dir = $parent
    }
    $ProjectRoot = $dir
}

$rawContent = [System.IO.File]::ReadAllText($XamlPath)
$findings = [System.Collections.ArrayList]::new()

# ============================================================
# CHECK 1: Well-formed XML
# ============================================================
try {
    $xml = [xml]$rawContent
} catch {
    $errMsg = $_.Exception.InnerException.Message
    if (-not $errMsg) { $errMsg = $_.Exception.Message }
    # .NET XML parser wraps the real error in a verbose message; extract just the inner error
    if ($errMsg -match 'Error:\s*"(.+)"') {
        $errMsg = $Matches[1]
    }

    # try to extract line/position from the .NET XML parser error
    $errLine = 0
    if ($errMsg -match 'line (\d+)') {
        $errLine = [int]$Matches[1]
    }

    $findings.Add((Out-Finding `
        -Rule 'xml-malformed' `
        -Severity 'error' `
        -Message "File is not valid XML: $errMsg" `
        -Fix "Fix the XML syntax error. Common causes: unclosed tag, mismatched angle brackets, unescaped '&' (use '&amp;'), or stray characters outside elements." `
        -Line $errLine
    )) | Out-Null

    # can't run further checks on broken XML
    ConvertTo-Json -InputObject @($findings) -Depth 5
    exit 0
}

$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('x', 'http://schemas.microsoft.com/winfx/2006/xaml')
$ns.AddNamespace('sap2010', 'http://schemas.microsoft.com/netfx/2010/xaml/activities/presentation')
$ns.AddNamespace('mca', 'clr-namespace:Microsoft.CSharp.Activities;assembly=Microsoft.CSharp.Activities')

$root = $xml.DocumentElement

# ============================================================
# CHECK 2: x:Class matches file path
# ============================================================
$xClass = $root.GetAttribute('Class', 'http://schemas.microsoft.com/winfx/2006/xaml')
if ($xClass -and $ProjectRoot) {
    $relPath = $XamlPath
    if ($XamlPath.StartsWith($ProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relPath = $XamlPath.Substring($ProjectRoot.Length).TrimStart('\', '/')
    }
    $expectedClass = [System.IO.Path]::ChangeExtension($relPath, $null).TrimEnd('.') -replace '[/\\]', '_'

    if ($xClass -ne $expectedClass) {
        # check for the common dots-instead-of-underscores mistake
        $hasDots = $xClass -match '\.'
        $fixMsg = "Change x:Class from '$xClass' to '$expectedClass' in the root <Activity> element."
        if ($hasDots) {
            $fixMsg += " Use underscores (_) for folder separators, NOT dots."
        }

        $findings.Add((Out-Finding `
            -Rule 'xclass-mismatch' `
            -Severity 'error' `
            -Message "x:Class is '$xClass' but file path requires '$expectedClass'." `
            -Fix $fixMsg `
            -Line (Get-LineNumber $rawContent 'x:Class')
        )) | Out-Null
    }
}

# ============================================================
# CHECK 3: Expression language consistency
# ============================================================
$projectJson = $null
$exprLang = $null
if ($ProjectRoot -and (Test-Path (Join-Path $ProjectRoot 'project.json'))) {
    $projectJson = Get-Content (Join-Path $ProjectRoot 'project.json') -Raw | ConvertFrom-Json
    $exprLang = $projectJson.expressionLanguage
}

if ($exprLang) {
    $hasBracketExpr = $rawContent -match '\[(?!x:)[^\]]+\]' -and $rawContent -notmatch '<CSharpValue'
    $hasCSharpValue = $rawContent -match '<CSharpValue|<CSharpReference|<mca:CSharpValue|<mca:CSharpReference'
    $hasVBSettings = $rawContent -match 'VisualBasic\.Settings'

    if ($exprLang -eq 'CSharp') {
        # C# project: should NOT have VB bracket expressions (unless they're literal strings like Shortcuts)
        # Look for bracket patterns that are clearly VB expressions on activity properties
        $vbPatternLines = @()
        $lines = $rawContent -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            # Match: PropertyName="[expression]" but skip Shortcuts= and literal {x: patterns
            if ($line -match '(?<!=Shortcuts)\s+\w+="(\[(?!x:)[^\]]*\])"' -and
                $line -notmatch 'Shortcuts=' -and
                $line -notmatch 'sap2010:WorkflowViewState\.IdRef') {
                $vbPatternLines += ($i + 1)
            }
        }

        if ($vbPatternLines.Count -gt 0 -and -not $hasCSharpValue) {
            $findings.Add((Out-Finding `
                -Rule 'expr-lang-mismatch' `
                -Severity 'error' `
                -Message "Project uses C# but XAML contains VB-style bracket expressions (lines: $($vbPatternLines -join ', ')). This causes 'multiple expression languages' errors." `
                -Fix "Replace [bracket] expressions with <CSharpValue>/<CSharpReference> elements. Example: Instead of Message=""[myVar]"", use <InArgument x:TypeArguments=""x:String""><CSharpValue x:TypeArguments=""x:String"">myVar</CSharpValue></InArgument>." `
                -Line $vbPatternLines[0]
            )) | Out-Null
        }
    }
    elseif ($exprLang -eq 'VisualBasic') {
        if ($hasCSharpValue) {
            $findings.Add((Out-Finding `
                -Rule 'expr-lang-mismatch' `
                -Severity 'error' `
                -Message "Project uses VisualBasic but XAML contains <CSharpValue>/<CSharpReference> elements. This causes 'multiple expression languages' errors." `
                -Fix "Replace <CSharpValue>/<CSharpReference> with VB bracket expressions. Example: Instead of <CSharpValue x:TypeArguments=""x:String"">myVar</CSharpValue>, use [myVar]." `
                -Line (Get-LineNumber $rawContent 'CSharpValue')
            )) | Out-Null
        }
    }
}

# ============================================================
# CHECK 4: Bad type prefixes (x:DateTime, x:Exception, etc.)
# ============================================================
$badXTypes = @(
    @{ pattern = 'x:DateTime';       correct = 's:DateTime' }
    @{ pattern = 'x:DateTimeOffset'; correct = 's:DateTimeOffset' }
    @{ pattern = 'x:Exception';      correct = 's:Exception' }
    @{ pattern = 'x:Guid';           correct = 's:Guid' }
    @{ pattern = 'x:Uri';            correct = 's:Uri' }
)

foreach ($bt in $badXTypes) {
    if ($rawContent -match [regex]::Escape($bt.pattern)) {
        $needsXmlns = $rawContent -notmatch 'xmlns:s\s*='

        $fix = "Replace all occurrences of '$($bt.pattern)' with '$($bt.correct)'."
        if ($needsXmlns) {
            $fix += " Also add xmlns:s=""clr-namespace:System;assembly=System.Private.CoreLib"" to the root <Activity> element."
        }

        $findings.Add((Out-Finding `
            -Rule 'bad-type-prefix' `
            -Severity 'error' `
            -Message "Used '$($bt.pattern)' which is not registered in the XAML language schema. The x: prefix only covers primitives (x:String, x:Int32, x:Boolean, etc.)." `
            -Fix $fix `
            -Line (Get-LineNumber $rawContent $bt.pattern)
        )) | Out-Null
    }
}

# also check if s: types are used without the xmlns:s declaration
if ($rawContent -match '"s:' -and $rawContent -notmatch 'xmlns:s\s*=') {
    $findings.Add((Out-Finding `
        -Rule 'missing-xmlns-s' `
        -Severity 'error' `
        -Message "XAML uses 's:' type prefix but xmlns:s is not declared on the root element." `
        -Fix "Add xmlns:s=""clr-namespace:System;assembly=System.Private.CoreLib"" to the root <Activity> element." `
        -Line 1
    )) | Out-Null
}

# ============================================================
# CHECK 5: Duplicate IdRef values
# ============================================================
$idRefs = [regex]::Matches($rawContent, 'WorkflowViewState\.IdRef="([^"]+)"')
$idRefMap = @{}
foreach ($match in $idRefs) {
    $val = $match.Groups[1].Value
    if ($idRefMap.ContainsKey($val)) {
        $idRefMap[$val]++
    } else {
        $idRefMap[$val] = 1
    }
}

$dupes = $idRefMap.GetEnumerator() | Where-Object { $_.Value -gt 1 }
foreach ($dupe in $dupes) {
    $findings.Add((Out-Finding `
        -Rule 'duplicate-idref' `
        -Severity 'error' `
        -Message "Duplicate WorkflowViewState.IdRef '$($dupe.Key)' appears $($dupe.Value) times. Each activity must have a unique IdRef." `
        -Fix "Rename duplicate IdRef values. Convention: ActivityType_N (e.g., Sequence_1, Sequence_2, LogMessage_1)." `
        -Line (Get-LineNumber $rawContent "IdRef=""$($dupe.Key)""")
    )) | Out-Null
}

# ============================================================
# CHECK 6: Missing required xmlns declarations
# ============================================================
# Check if UiPath activities are used without the ui xmlns
$usesUiActivities = $rawContent -match '<ui:' -or $rawContent -match 'xmlns:ui='
$hasUiXmlns = $rawContent -match 'xmlns:ui\s*=\s*"http://schemas\.uipath\.com/workflow/activities"'

if ($rawContent -match '<ui:' -and -not $hasUiXmlns) {
    $findings.Add((Out-Finding `
        -Rule 'missing-xmlns-ui' `
        -Severity 'error' `
        -Message "XAML uses 'ui:' prefix for UiPath activities but xmlns:ui is not declared." `
        -Fix 'Add xmlns:ui="http://schemas.uipath.com/workflow/activities" to the root <Activity> element.' `
        -Line 1
    )) | Out-Null
}

# Check for sap2010 usage without declaration
if ($rawContent -match 'sap2010:' -and $rawContent -notmatch 'xmlns:sap2010\s*=') {
    $findings.Add((Out-Finding `
        -Rule 'missing-xmlns-sap2010' `
        -Severity 'error' `
        -Message "XAML uses 'sap2010:' prefix but xmlns:sap2010 is not declared." `
        -Fix 'Add xmlns:sap2010="http://schemas.microsoft.com/netfx/2010/xaml/activities/presentation" to the root <Activity> element.' `
        -Line 1
    )) | Out-Null
}

# Check for sco usage without declaration (common in NamespacesForImplementation)
if ($rawContent -match '<sco:' -and $rawContent -notmatch 'xmlns:sco\s*=') {
    $findings.Add((Out-Finding `
        -Rule 'missing-xmlns-sco' `
        -Severity 'error' `
        -Message "XAML uses 'sco:' prefix but xmlns:sco is not declared." `
        -Fix 'Add xmlns:sco="clr-namespace:System.Collections.ObjectModel;assembly=System.Private.CoreLib" to the root <Activity> element or inline where used.' `
        -Line (Get-LineNumber $rawContent '<sco:')
    )) | Out-Null
}

# ============================================================
# CHECK 7: Wrong assembly in xmlns (mscorlib vs System.Private.CoreLib)
# ============================================================
if ($rawContent -match 'assembly=mscorlib') {
    $findings.Add((Out-Finding `
        -Rule 'wrong-assembly-mscorlib' `
        -Severity 'error' `
        -Message "XAML references 'assembly=mscorlib' which is the .NET Framework assembly name. UiPath Windows/Portable projects use .NET (Core) assemblies." `
        -Fix "Replace 'assembly=mscorlib' with 'assembly=System.Private.CoreLib' in all xmlns declarations." `
        -Line (Get-LineNumber $rawContent 'assembly=mscorlib')
    )) | Out-Null
}

# ============================================================
# CHECK 8: Literal curly braces in attribute values
# ============================================================
$lines = $rawContent -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    # Match: Property="{Something}" where Something is NOT a known XAML extension
    # Known extensions: x:Null, x:Reference, x:Static, Binding, StaticResource, DynamicResource
    $curlyMatches = [regex]::Matches($line, '(\w+)="\{(?!x:|Binding|StaticResource|DynamicResource|RelativeSource|\})([^"]*)\}"')
    foreach ($cm in $curlyMatches) {
        $propName = $cm.Groups[1].Value
        $innerVal = $cm.Groups[2].Value
        # skip known XAML markup extensions
        if ($innerVal -match '^(Null|Reference|Static|Type)') { continue }

        $findings.Add((Out-Finding `
            -Rule 'literal-curly-brace' `
            -Severity 'warning' `
            -Message "Property '$propName' value starts with '{$innerVal}' which XAML parses as a markup extension. If this is a literal string (e.g., a template placeholder), it will fail." `
            -Fix "Prefix with escape sequence: $propName=""{}{$innerVal}..."" to indicate a literal string." `
            -Line ($i + 1)
        )) | Out-Null
    }
}

# ============================================================
# CHECK 9: Missing TextExpression sections
# ============================================================
$hasNamespaces = $rawContent -match 'TextExpression\.NamespacesForImplementation'
$hasReferences = $rawContent -match 'TextExpression\.ReferencesForImplementation'

if (-not $hasNamespaces -and -not $hasReferences) {
    $findings.Add((Out-Finding `
        -Rule 'missing-text-expressions' `
        -Severity 'warning' `
        -Message "XAML is missing both TextExpression.NamespacesForImplementation and TextExpression.ReferencesForImplementation sections. Expressions referencing external types will fail." `
        -Fix "Add NamespacesForImplementation (with System, System.Collections.Generic, System.Linq at minimum) and ReferencesForImplementation (with System, System.Activities assembly refs). Copy from an existing workflow in the same project." `
        -Line 1
    )) | Out-Null
}

# ============================================================
# CHECK 10: Duplicate x:Reference / x:Name IDs (flowcharts/state machines)
# ============================================================
$xNameMatches = [regex]::Matches($rawContent, 'x:Name="([^"]+)"')
$xNameMap = @{}
foreach ($match in $xNameMatches) {
    $val = $match.Groups[1].Value
    if ($xNameMap.ContainsKey($val)) {
        $xNameMap[$val]++
    } else {
        $xNameMap[$val] = 1
    }
}

$xNameDupes = $xNameMap.GetEnumerator() | Where-Object { $_.Value -gt 1 }
foreach ($dupe in $xNameDupes) {
    $findings.Add((Out-Finding `
        -Rule 'duplicate-xname' `
        -Severity 'error' `
        -Message "Duplicate x:Name '$($dupe.Key)' appears $($dupe.Value) times. Each x:Name must be unique within the file (used for x:Reference linking in Flowcharts/StateMachines)." `
        -Fix "Rename duplicate x:Name values. Use incrementing numbers: __ReferenceID0, __ReferenceID1, etc." `
        -Line (Get-LineNumber $rawContent "x:Name=""$($dupe.Key)""")
    )) | Out-Null
}

# ============================================================
# CHECK 11: Duplicate x:Key values in Dictionary elements
# ============================================================
# Find all Dictionary elements and check for duplicate keys within each
$dictMatches = [regex]::Matches($rawContent, '(?s)<(?:\w+:)?Dictionary[^>]*>(.*?)</(?:\w+:)?Dictionary>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
foreach ($dictMatch in $dictMatches) {
    $dictContent = $dictMatch.Value
    $keyMatches = [regex]::Matches($dictContent, 'x:Key="([^"]+)"')
    $keyMap = @{}
    foreach ($km in $keyMatches) {
        $keyVal = $km.Groups[1].Value
        if ($keyMap.ContainsKey($keyVal)) {
            $keyMap[$keyVal]++
        } else {
            $keyMap[$keyVal] = 1
        }
    }
    $keyDupes = $keyMap.GetEnumerator() | Where-Object { $_.Value -gt 1 }
    foreach ($kd in $keyDupes) {
        $findings.Add((Out-Finding `
            -Rule 'duplicate-dictionary-key' `
            -Severity 'error' `
            -Message "Duplicate x:Key '$($kd.Key)' in Dictionary element ($($kd.Value) occurrences). Studio throws 'Key property has already been set on Dictionary' and refuses to load the file." `
            -Fix "Remove the duplicate entry. Each x:Key in a Dictionary must be unique. Search for x:Key=""$($kd.Key)"" and keep only one." `
            -Line (Get-LineNumber $rawContent "x:Key=""$($kd.Key)""")
        )) | Out-Null
    }
}

# ============================================================
# CHECK 12: Duplicate properties on same element (XamlDuplicateMemberException)
# ============================================================
# XAML doesn't allow the same attribute twice on one element. XML parsers usually
# silently take the last value, but the XAML runtime throws XamlDuplicateMemberException.
# Scan for elements with repeated attribute names.
$elementMatches = [regex]::Matches($rawContent, '<(\w+[\:\w]*)\s([^>]+?)/?>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
foreach ($elem in $elementMatches) {
    $elemName = $elem.Groups[1].Value
    $attrsText = $elem.Groups[2].Value
    $attrNames = [regex]::Matches($attrsText, '(?:^|\s)(\w+[\:\w]*)=')
    $attrMap = @{}
    foreach ($an in $attrNames) {
        $aName = $an.Groups[1].Value
        if ($attrMap.ContainsKey($aName)) {
            $attrMap[$aName]++
        } else {
            $attrMap[$aName] = 1
        }
    }
    $attrDupes = $attrMap.GetEnumerator() | Where-Object { $_.Value -gt 1 }
    foreach ($ad in $attrDupes) {
        $findings.Add((Out-Finding `
            -Rule 'duplicate-attribute' `
            -Severity 'error' `
            -Message "Element '<$elemName>' has attribute '$($ad.Key)' set $($ad.Value) times. Studio throws 'property has already been set' and refuses to load." `
            -Fix "Remove the duplicate '$($ad.Key)' attribute from the <$elemName> element. Keep only one." `
            -Line (Get-LineNumber $rawContent $elemName)
        )) | Out-Null
    }
}

# ============================================================
# OUTPUT
# ============================================================
if ($findings.Count -eq 0) {
    Write-Output '[]'
} else {
    ConvertTo-Json -InputObject @($findings) -Depth 5
}
