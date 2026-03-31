# Comprehensive Test Plan

40 workflows across 10 projects. Each test is a fresh conversation with no prior context.
Tests are grouped by project — the model creates the project in the first test of each group, then adds workflows in subsequent tests.

**Scoring:** 0-10 per test. Total: 400 points.
**Thresholds:** Excellent 320+ (80%), Good 240-319 (60%), Marginal 160-239 (40%), Failing <160.

## Pre-test checklist

1. Studio Desktop is running
2. Create folder `C:\Users\Alberto\Desktop\SkillTests` (if it doesn't exist)
3. Delete leftover project folders from previous runs
4. Fresh conversation per test — no prior context

---

# Project 1: FileOps (VB, Windows)

File and folder operations. Tests built-in System.Activities file capabilities.

## T01: Create project + read/write text file

### User prompt
```
Create a UiPath project called "FileOps" in C:\Users\Alberto\Desktop\SkillTests, VisualBasic, Windows. Write a workflow that creates a text file at "Output/greeting.txt" with the content "Hello from UiPath!", then reads it back and logs the content. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` log contains "Hello from UiPath!"
- File `Output/greeting.txt` exists with correct content

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Project created, file written and read, log confirms content |
| 8-9 | Works after 1 fix cycle (e.g., missing folder creation) |
| 6-7 | File operations work but needed multiple fix cycles |
| 4-5 | Project created but file ops don't validate |
| 2-3 | Couldn't find the right activities |
| 0-1 | Didn't follow skill at all |

---

## T02: Scan folder + filter by extension

### User prompt
```
In the FileOps project, add a workflow "FilterFiles.xaml" that scans the project root folder, collects all .xaml file names into a List(Of String), then logs each file name. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs at least "Main.xaml" and "FilterFiles.xaml"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Clean, lists all .xaml files correctly |
| 8-9 | Works but used Directory.GetFiles via InvokeCode instead of ForEachFile |
| 6-7 | Logs files but with path issues or extra fix cycles |
| 4-5 | Activity found but type/scope errors unresolved |
| 2-3 | Wrong approach entirely |
| 0-1 | No attempt |

---

## T03: Copy and move files

### User prompt
```
In FileOps, create "OrganizeFiles.xaml". It should: 1) Create folders "Archive" and "Backup" in the project dir. 2) Copy "Output/greeting.txt" to "Backup/greeting.txt". 3) Move "Output/greeting.txt" to "Archive/greeting.txt". Log "Done organizing" when finished. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` completes, "Backup/greeting.txt" and "Archive/greeting.txt" exist
- "Output/greeting.txt" no longer exists (it was moved)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | All three operations work, correct file locations |
| 8-9 | Works but needed fix cycle on path handling |
| 6-7 | Copy works, move has issues or vice versa |
| 4-5 | Found activities but property errors |
| 2-3 | Couldn't configure file activities |
| 0-1 | No attempt |

---

## T04: Compress files to ZIP

### User prompt
```
In FileOps, add "ZipFiles.xaml" that compresses the entire "Backup" folder into "Backup.zip" in the project root. Log the zip file path when done. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` creates `Backup.zip`

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | ZIP created with correct contents |
| 8-9 | Works after finding CompressFiles activity |
| 6-7 | Multiple fix cycles but works |
| 4-5 | Activity found but configuration wrong |
| 2-3 | Couldn't find compress activity |
| 0-1 | No attempt |

---

# Project 2: DataPipe (VB, Windows)

CSV and DataTable manipulation. Tests data transformation patterns.

## T05: Read CSV + filter rows

### User prompt
```
Create project "DataPipe" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. First, create a CSV file "Data/employees.csv" with these columns and 5 rows:
Name,Department,Salary
Alice,Engineering,85000
Bob,Sales,52000
Carol,Engineering,92000
Dave,Sales,48000
Eve,Engineering,78000

Then create a workflow that reads this CSV into a DataTable, filters to only Engineering employees (Salary > 80000), and logs each matching name. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "Alice" and "Carol" (not Bob, Dave, or Eve)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | CSV created, read, filtered correctly, logs Alice and Carol |
| 8-9 | Works but used string comparison initially, fixed with CDbl |
| 6-7 | Filter logic correct but needed multiple fix cycles on types |
| 4-5 | CSV read works but filter fails |
| 2-3 | Couldn't read CSV |
| 0-1 | No attempt |

---

## T06: Build DataTable + add rows + sort

### User prompt
```
In DataPipe, create "BuildTable.xaml" that programmatically builds a DataTable with columns "Product" (String) and "Price" (Double). Add 4 rows: Laptop/999.99, Mouse/29.99, Keyboard/79.99, Monitor/349.99. Sort by Price descending. Log each row as "Product: $Price". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs rows in order: Laptop, Monitor, Keyboard, Mouse

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Table built, sorted, logged in correct order |
| 8-9 | Works after fixing DataTable.DefaultView sort syntax |
| 6-7 | DataTable built but sorting needed fix cycles |
| 4-5 | DataTable created but can't add rows or sort |
| 2-3 | Wrong approach to building DataTable |
| 0-1 | No attempt |

---

## T07: Merge two DataTables + write CSV

### User prompt
```
In DataPipe, create "MergeExport.xaml". Read "Data/employees.csv" into a DataTable. Build a second DataTable with same columns and one row: Frank,Marketing,67000. Merge the second into the first. Write the merged result to "Data/all_employees.csv". Log the total row count. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "6" (5 original + 1 new)
- `all_employees.csv` has 6 data rows

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Merge and CSV export both correct |
| 8-9 | Works after fixing Merge method or CSV write config |
| 6-7 | Merge works but CSV export has issues |
| 4-5 | One of the two operations works |
| 2-3 | Couldn't merge DataTables |
| 0-1 | No attempt |

---

## T08: Lookup DataTable

### User prompt
```
In DataPipe, create "LookupEmployee.xaml". Read "Data/employees.csv". Use LookupDataTable activity to find the salary of "Carol". Log "Carol earns: 92000". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "Carol earns: 92000"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | LookupDataTable configured correctly, logs the value |
| 8-9 | Works after fixing OverloadGroup (ColumnIndex vs ColumnName) |
| 6-7 | Used LINQ instead of LookupDataTable but works |
| 4-5 | Found activity but configuration errors |
| 2-3 | Couldn't configure lookup |
| 0-1 | No attempt |

---

# Project 3: WebClient (C#, Windows)

C# expression language project. Tests CSharpValue/CSharpReference syntax and HTTP patterns.

## T09: Create C# project + HTTP GET + JSON parse

### User prompt
```
Create project "WebClient" in C:\Users\Alberto\Desktop\SkillTests with CSharp expression language, Windows framework. Create a workflow that makes an HTTP GET request to "https://jsonplaceholder.typicode.com/users/1", deserializes the JSON response, and logs the user's name and email. Run it.
```

### Validation
- `project.json` has `"expressionLanguage": "CSharp"`
- `get-errors` returns 0
- `run-file` logs "Leanne Graham" and "Sincere@april.biz"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | C# project, HTTP call, JSON parse, correct output |
| 8-9 | Works after fixing CSharpValue syntax (used VB brackets initially) |
| 6-7 | HTTP works but JSON parsing needed fix cycles |
| 4-5 | C# project created but expression errors |
| 2-3 | Fell back to VB or couldn't create C# project |
| 0-1 | No attempt |

---

## T10: HTTP POST with JSON body (C#)

### User prompt
```
In WebClient, create "CreatePost.xaml". Make an HTTP POST to "https://jsonplaceholder.typicode.com/posts" with JSON body: {"title":"Test Post","body":"Hello from UiPath","userId":1}. Set Content-Type header to "application/json". Log the response status code and the returned "id" field. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs status code 201 and an id value

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | POST with JSON body, headers, correct response parsing |
| 8-9 | Works after fixing header configuration or body format |
| 6-7 | POST succeeds but response parsing needs fixes |
| 4-5 | HTTP configured but body or headers wrong |
| 2-3 | Couldn't configure POST request |
| 0-1 | No attempt |

---

## T11: Paginated API loop (C#)

### User prompt
```
In WebClient, create "ListUsers.xaml". Fetch users from "https://jsonplaceholder.typicode.com/users" (returns array of 10 users). Deserialize the JSON array. Loop through each user and log "Name: {name} - Company: {company.name}". Log the total count at the end. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs 10 user entries with name and company

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Array deserialized, loop with nested JSON property access |
| 8-9 | Works after fixing JToken access syntax in C# |
| 6-7 | List fetched but nested property access needed fixes |
| 4-5 | HTTP works but deserialization or loop fails |
| 2-3 | Couldn't handle JSON array |
| 0-1 | No attempt |

---

## T12: Download file from URL (C#)

### User prompt
```
In WebClient, create "DownloadFile.xaml". Download the file at "https://jsonplaceholder.typicode.com/todos" and save the response body to "Output/todos.json". Log "Downloaded {fileSize} bytes" where fileSize is the length of the saved content. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` creates `Output/todos.json` with valid JSON content
- Log shows byte count

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | File downloaded, saved, size logged |
| 8-9 | Works after fixing file write or size calculation |
| 6-7 | Download works but file save needs fixes |
| 4-5 | HTTP works but save-to-file fails |
| 2-3 | Couldn't configure download |
| 0-1 | No attempt |

---

# Project 4: TextProcessor (VB, Windows)

String manipulation, Regex, and InvokeCode patterns.

## T13: Regex extract emails and phones

### User prompt
```
Create project "TextProcessor" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. Create a workflow that takes this text as an Assign:
"Contact us at support@example.com or sales@company.org. Call 555-123-4567 or 555-987-6543."
Use Matches activity (System.Text.RegularExpressions) to extract all email addresses and phone numbers. Log each match. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs: support@example.com, sales@company.org, 555-123-4567, 555-987-6543

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Both regex patterns work, all 4 values extracted |
| 8-9 | Works after fixing regex pattern syntax or Matches output type |
| 6-7 | Emails or phones extracted but not both |
| 4-5 | Matches activity found but regex or output binding wrong |
| 2-3 | Couldn't configure Matches activity |
| 0-1 | No attempt |

---

## T14: String Split + Dictionary building

### User prompt
```
In TextProcessor, create "ParseConfig.xaml". Take this config string:
"host=localhost;port=5432;database=mydb;user=admin"
Split by ";" then split each part by "=". Build a Dictionary(Of String, String) with the key-value pairs. Log each pair as "Key=Value". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs: host=localhost, port=5432, database=mydb, user=admin

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Dictionary built correctly, all 4 pairs logged |
| 8-9 | Works after fixing Dictionary type declaration or Split syntax |
| 6-7 | Parsing works but Dictionary creation needed fixes |
| 4-5 | Split works but Dictionary fails |
| 2-3 | Couldn't declare Dictionary variable |
| 0-1 | No attempt |

---

## T15: InvokeCode VB.NET

### User prompt
```
In TextProcessor, create "CustomCode.xaml". Use InvokeCode activity with VB.NET to: take a string argument "Hello World UiPath Automation" and return the word count as an Int32. Log "Word count: {result}". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "Word count: 4"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | InvokeCode with arguments, correct word count |
| 8-9 | Works after fixing argument direction or type binding |
| 6-7 | InvokeCode runs but argument passing needed fixes |
| 4-5 | InvokeCode activity added but doesn't compile |
| 2-3 | Couldn't configure InvokeCode |
| 0-1 | No attempt |

---

## T16: String formatting + type conversions

### User prompt
```
In TextProcessor, create "FormatReport.xaml". Declare variables: name="Alice" (String), age=30 (Int32), salary=85000.50 (Double), startDate=DateTime.Now (DateTime). Log a single formatted message: "Employee: Alice, Age: 30, Salary: $85,000.50, Started: {date in MM/dd/yyyy format}". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs the formatted string with correct values

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | All types declared correctly, formatted string logs |
| 8-9 | Works after fixing DateTime declaration (s:DateTime) or format string |
| 6-7 | Most types work but DateTime or Double formatting needed fixes |
| 4-5 | Variable declarations have type errors |
| 2-3 | Couldn't declare DateTime or Double variables |
| 0-1 | No attempt |

---

# Project 5: ExcelPro (VB, Windows)

Advanced Excel operations beyond basic read/write.

## T17: Read multiple sheets + merge

### User prompt
```
Create project "ExcelPro" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. First, create an Excel file "Data/Sales.xlsx" with two sheets:
Sheet "Q1": Name,Revenue — Alice,50000; Bob,35000
Sheet "Q2": Name,Revenue — Alice,62000; Carol,41000
Then create a workflow that reads both sheets into separate DataTables, merges them, and logs the total row count (should be 4). Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "4"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Both sheets read, merged, count correct |
| 8-9 | Works after fixing sheet name binding or merge |
| 6-7 | Reads work but merge needed fixes |
| 4-5 | One sheet reads, second fails |
| 2-3 | Couldn't read Excel with multiple sheets |
| 0-1 | No attempt |

---

## T18: LINQ GroupBy + aggregate on DataTable

### User prompt
```
In ExcelPro, create "SalesSummary.xaml". Read both sheets from "Data/Sales.xlsx", merge them, then use LINQ to group by Name and sum Revenue per person. Log each result as "Name: TotalRevenue". Alice should have 112000, Bob 35000, Carol 41000. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs correct totals for each person

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | GroupBy + Sum works, all 3 results correct |
| 8-9 | Works after fixing LINQ syntax or type conversion |
| 6-7 | Grouping works but sum has type issues |
| 4-5 | LINQ expression doesn't compile |
| 2-3 | Fell back to manual loop (acceptable but lower score) |
| 0-1 | No attempt |

---

## T19: Excel write with formatting + new sheet

### User prompt
```
In ExcelPro, create "WriteReport.xaml". Build a DataTable with columns "Name" (String) and "Total" (Double) containing: Alice/112000, Bob/35000, Carol/41000. Write it to a NEW sheet called "Summary" in "Data/Sales.xlsx" with headers. Log "Report written". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` creates "Summary" sheet with 3 rows + header

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | New sheet created with correct data |
| 8-9 | Works after fixing sheet creation or DataTable write config |
| 6-7 | Data written but to wrong sheet or without headers |
| 4-5 | Write activity found but configuration errors |
| 2-3 | Couldn't write to Excel |
| 0-1 | No attempt |

---

# Project 6: FlowLogic (VB, Windows)

Flowchart workflows, Switch/Case, Do While. Tests non-Sequence layouts.

## T20: Flowchart with multiple decision branches

### User prompt
```
Create project "FlowLogic" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. Create "GradeCalculator.xaml" as a Flowchart (not Sequence). It should: take a score variable (Int32, default 75), then branch: score >= 90 logs "A", score >= 80 logs "B", score >= 70 logs "C", score >= 60 logs "D", else logs "F". Run it (should log "C").
```

### Validation
- `get-errors` returns 0
- XAML uses `<Flowchart>` root, not `<Sequence>`
- `run-file` logs "C"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Flowchart layout with FlowDecision nodes, correct output |
| 8-9 | Works but used nested If in Sequence instead of Flowchart |
| 6-7 | Flowchart structure correct but decision wiring needed fixes |
| 4-5 | Flowchart created but FlowDecision configuration wrong |
| 2-3 | Fell back to Sequence (accepted but lower score) |
| 0-1 | No attempt |

---

## T21: Switch/Case activity

### User prompt
```
In FlowLogic, create "DayRouter.xaml". Declare a variable dayOfWeek (String, default "Monday"). Use a Switch(Of String) activity to route: "Monday"/"Wednesday"/"Friday" logs "Weekday work", "Tuesday"/"Thursday" logs "Meeting day", "Saturday"/"Sunday" logs "Weekend". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "Weekday work" (since default is Monday)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Switch activity with all cases, correct routing |
| 8-9 | Works after fixing Switch type argument or case syntax |
| 6-7 | Some cases work, others have syntax issues |
| 4-5 | Switch activity found but can't configure cases |
| 2-3 | Used If/ElseIf chain instead (accepted but lower score) |
| 0-1 | No attempt |

---

## T22: Do While loop with exit condition

### User prompt
```
In FlowLogic, create "Countdown.xaml". Use a DoWhile activity that starts counter at 10, decrements by 1 each iteration, logs the counter value, and exits when counter reaches 0. Log "Liftoff!" at the end. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs 10, 9, 8... 1, then "Liftoff!"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | DoWhile with correct condition, all values logged |
| 8-9 | Works after fixing condition direction (While vs DoWhile) |
| 6-7 | Loop works but off-by-one error |
| 4-5 | DoWhile found but condition errors |
| 2-3 | Used While instead (accepted but lower score) |
| 0-1 | No attempt |

---

## T23: Retry Scope pattern

### User prompt
```
In FlowLogic, create "RetryDemo.xaml". Use a RetryScope activity (NumberOfRetries=3, RetryInterval=00:00:01). Inside the Action, use InvokeCode to generate a random number 1-10; if it's less than 8, throw an exception "Random failure". In the Condition, just check if the action succeeded. Log "Succeeded after retries" at the end. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` either succeeds (logs message) or fails after 3 retries

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | RetryScope configured with action + condition, runs |
| 8-9 | Works after fixing RetryScope property configuration |
| 6-7 | RetryScope structure correct but InvokeCode or condition has issues |
| 4-5 | Found activity but can't wire action/condition |
| 2-3 | Couldn't find or configure RetryScope |
| 0-1 | No attempt |

---

# Project 7: ErrorMaster (VB, Windows)

Advanced error handling patterns. Nested TryCatch, multiple catch types, exception properties.

## T24: Multiple catch blocks with different exception types

### User prompt
```
Create project "ErrorMaster" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. Create "MultiCatch.xaml" with a TryCatch. In the Try block, use InvokeCode to: Integer.Parse("not_a_number"). Add TWO catch blocks: one for System.FormatException that logs "Format error: " + exception.Message, and one for System.Exception (generic fallback) that logs "Unexpected: " + exception.Message. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "Format error: ..." (FormatException is caught, not the generic)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Two catch blocks, FormatException caught specifically |
| 8-9 | Works after fixing FormatException type declaration |
| 6-7 | Both catches exist but wrong one fires |
| 4-5 | Single catch block works (partial credit) |
| 2-3 | TryCatch structure wrong |
| 0-1 | No attempt |

---

## T25: Nested TryCatch

### User prompt
```
In ErrorMaster, create "NestedTry.xaml". Outer TryCatch: in the Try, do an inner TryCatch. Inner Try: log "Step 1", then throw New Exception("Inner error"). Inner Catch: log "Caught inner: " + exception.Message, then throw New Exception("Escalated"). Outer Catch: log "Caught outer: " + exception.Message. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs: "Step 1", "Caught inner: Inner error", "Caught outer: Escalated"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Nested TryCatch, exception escalation works correctly |
| 8-9 | Works after fixing Throw activity or exception construction |
| 6-7 | Nesting correct but exception re-throw has issues |
| 4-5 | Inner TryCatch works, outer doesn't catch escalation |
| 2-3 | Can't nest TryCatch blocks |
| 0-1 | No attempt |

---

## T26: Finally block + cleanup pattern

### User prompt
```
In ErrorMaster, create "CleanupPattern.xaml". Use TryCatch with a Finally block. In Try: log "Processing", then Assign result = 100 / 0 (force divide by zero). In Catch(Exception): log "Error handled". In Finally: log "Cleanup complete". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs: "Processing", "Error handled", "Cleanup complete" (Finally always runs)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Try + Catch + Finally all execute in correct order |
| 8-9 | Works after fixing divide-by-zero expression or Finally syntax |
| 6-7 | Try/Catch works but Finally doesn't execute |
| 4-5 | TryCatch works, Finally block missing or wrong |
| 2-3 | Can't add Finally block |
| 0-1 | No attempt |

---

# Project 8: Orchestrator (VB, Windows)

Sub-workflow orchestration, arguments, config patterns. Tests multi-file composition.

## T27: Config reader from Excel

### User prompt
```
Create project "Orchestrator" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. Create an Excel file "Config/Settings.xlsx" with sheet "Config" containing:
Name,Value
AppName,InvoiceBot
MaxRetries,3
OutputFolder,C:\Temp\Output

Create "ReadConfig.xaml" that reads this sheet into a DataTable and builds a Dictionary(Of String, String) from the Name/Value columns. Log each setting. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs all 3 settings

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Excel read + Dictionary built + all settings logged |
| 8-9 | Works after fixing Dictionary declaration or row access |
| 6-7 | Excel read works but Dictionary building needs fixes |
| 4-5 | Excel read works but Dictionary fails |
| 2-3 | Couldn't read config Excel |
| 0-1 | No attempt |

---

## T28: Sub-workflow with In/Out/InOut arguments

### User prompt
```
In Orchestrator, create "Helpers/ValidateInput.xaml" with three arguments: in_Text (In, String), io_Counter (InOut, Int32), out_IsValid (Out, Boolean). The workflow should: increment io_Counter by 1, set out_IsValid to (in_Text.Length > 3), log "Validated: {in_Text} -> {out_IsValid}".

Then create "TestArguments.xaml" that declares counter=0, invokes ValidateInput twice — first with "Hi" then with "Hello" — and logs "Counter: {counter}, Valid1: {result1}, Valid2: {result2}". Run TestArguments.
```

### Validation
- `get-errors` returns 0 for both files
- `run-file` logs: counter=2, Valid1=False, Valid2=True

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | All 3 argument directions work, counter incremented correctly |
| 8-9 | Works after fixing InOut argument syntax or Dictionary binding |
| 6-7 | In/Out work but InOut doesn't update |
| 4-5 | Sub-workflow created but argument binding fails |
| 2-3 | Couldn't set up multiple argument types |
| 0-1 | No attempt |

---

## T29: Main orchestrator calling 3 sub-workflows

### User prompt
```
In Orchestrator, create "Process/Init.xaml" (logs "Initializing..."), "Process/Execute.xaml" (logs "Executing..."), and "Process/Cleanup.xaml" (logs "Cleaning up..."). Then create "RunAll.xaml" that invokes all three in sequence using InvokeWorkflowFile. Add TryCatch around Execute — if it fails, still run Cleanup. Run RunAll.
```

### Validation
- `get-errors` returns 0 on all 4 files
- `run-file` on RunAll logs: "Initializing...", "Executing...", "Cleaning up..."

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | All 4 files created, invocation chain works, TryCatch protects Cleanup |
| 8-9 | Works after fixing x:Class names or invoke paths |
| 6-7 | Invocations work but TryCatch around Execute has issues |
| 4-5 | Some sub-workflows invoke correctly, others fail |
| 2-3 | Couldn't set up multi-file invocation |
| 0-1 | No attempt |

---

# Project 9: PdfMaster (VB, Windows)

PDF operations and document processing.

## T30: Generate PDF from text

### User prompt
```
Create project "PdfMaster" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. Install UiPath.PDF.Activities. Create "GeneratePdf.xaml" that converts the text "Invoice #1234\nDate: 2026-01-15\nTotal: $500.00" to a PDF file at "Output/invoice.pdf". Log "PDF created". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` creates "Output/invoice.pdf"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | PDF generated with correct content |
| 8-9 | Works after fixing ConvertTextToPDF configuration |
| 6-7 | PDF created but content or path issues |
| 4-5 | Activity found but property errors |
| 2-3 | Couldn't find PDF generation activity |
| 0-1 | No attempt |

---

## T31: Read PDF + extract to DataTable

### User prompt
```
In PdfMaster, create "ExtractPdf.xaml". Read the text from "Output/invoice.pdf" using ReadPDFText. Extract the invoice number and total using string operations or regex. Log "Invoice: #1234, Total: $500.00". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs the correct invoice number and total

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | PDF read + data extracted correctly |
| 8-9 | Works after fixing PDF read config or regex pattern |
| 6-7 | PDF reads but extraction needs fixes |
| 4-5 | ReadPDFText works but extraction fails |
| 2-3 | Couldn't read PDF |
| 0-1 | No attempt |

---

## T32: Merge two PDFs

### User prompt
```
In PdfMaster, create "MergePdfs.xaml". First create a second PDF "Output/receipt.pdf" from text "Receipt for payment received." Then merge "Output/invoice.pdf" and "Output/receipt.pdf" into "Output/combined.pdf" using JoinPDF activity. Log "Merged PDF created". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` creates "Output/combined.pdf"

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Both PDFs created, merged successfully |
| 8-9 | Works after fixing JoinPDF property configuration |
| 6-7 | Individual PDFs work, merge has issues |
| 4-5 | JoinPDF found but configuration wrong |
| 2-3 | Couldn't find merge activity |
| 0-1 | No attempt |

---

# Project 10: CSharpEdge (C#, Windows)

C# expression edge cases. Tests the hardest patterns in C# mode.

## T33: Assign with CSharpValue/CSharpReference

### User prompt
```
Create project "CSharpEdge" in C:\Users\Alberto\Desktop\SkillTests, CSharp, Windows. Create "BasicAssign.xaml" that declares three variables: message (String), count (Int32), timestamp (DateTime). Assign message = "Hello " + "World", count = 42, timestamp = DateTime.Now. Log all three. Run it.
```

### Validation
- `project.json` has `"expressionLanguage": "CSharp"`
- `get-errors` returns 0
- `run-file` logs all three values

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | C# project, all assigns use CSharpValue/CSharpReference, runs |
| 8-9 | Works after fixing expression syntax (used VB brackets) |
| 6-7 | String and Int work but DateTime needed s: prefix fix |
| 4-5 | C# project but expression compilation errors |
| 2-3 | Couldn't write C# expressions at all |
| 0-1 | No attempt |

---

## T34: ForEach with C# expressions

### User prompt
```
In CSharpEdge, create "CSharpLoop.xaml". Create a List<string> variable with values "Alpha", "Beta", "Gamma". ForEach through the list, and for each item log "Item: {item}, Length: {item.Length}". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs 3 items with correct lengths (5, 4, 5)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | List creation, ForEach, string interpolation all in C# |
| 8-9 | Works after fixing List initialization or ForEach type argument |
| 6-7 | Loop works but string formatting needed fixes |
| 4-5 | List created but ForEach has type errors |
| 2-3 | Couldn't create List in C# syntax |
| 0-1 | No attempt |

---

## T35: TryCatch with s:Exception in C#

### User prompt
```
In CSharpEdge, create "CSharpTryCatch.xaml". Add TryCatch: in Try, use InvokeCode with C# to: throw new InvalidOperationException("Test error"). Catch System.InvalidOperationException, log "Caught: " + exception.Message. Also add a generic System.Exception catch that logs "Unexpected". Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs "Caught: Test error" (specific catch, not generic)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | C# InvokeCode + TryCatch with specific exception type |
| 8-9 | Works after fixing exception type xmlns or InvokeCode language |
| 6-7 | TryCatch works but InvokeCode or specific catch has issues |
| 4-5 | Generic catch works, specific doesn't |
| 2-3 | TryCatch structure wrong for C# |
| 0-1 | No attempt |

---

## T36: Dictionary + JSON construction (C#)

### User prompt
```
In CSharpEdge, create "BuildJson.xaml". Create a Dictionary<string, object> with keys "name"="UiPath Bot", "version"=2, "active"=true. Serialize it to a JSON string using SerializeJson activity. Log the JSON output. Run it.
```

### Validation
- `get-errors` returns 0
- `run-file` logs valid JSON with all 3 key-value pairs

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | Dictionary created in C#, serialized to valid JSON |
| 8-9 | Works after fixing Dictionary type declaration or initialization |
| 6-7 | Dictionary works but serialization has issues |
| 4-5 | Dictionary declared but can't add items in C# |
| 2-3 | Couldn't declare Dictionary in C# |
| 0-1 | No attempt |

---

# Project Bonus: MailQueue (VB, Windows)

Email + multi-step orchestration patterns.

## T37: Send email with HTML body

### User prompt
```
Create project "MailQueue" in C:\Users\Alberto\Desktop\SkillTests, VB, Windows. Install UiPath.Mail.Activities. Create "SendReport.xaml" that sends an email via SMTP to "test@example.com" with subject "Daily Report", HTML body "<h1>Report</h1><p>All systems operational.</p>", from "bot@example.com". Use SMTP server "smtp.example.com" port 587. Don't actually need it to connect — just validate 0 errors.
```

### Validation
- `get-errors` returns 0
- XAML has correct SendMail activity with HTML body and SMTP config

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | SendMail configured with all properties, 0 validation errors |
| 8-9 | Works after fixing Password/SecurePassword conflict or IsBodyHtml |
| 6-7 | Activity configured but minor property errors remain |
| 4-5 | Activity found but significant config errors |
| 2-3 | Couldn't configure SMTP mail |
| 0-1 | No attempt |

---

## T38: Read emails with IMAP

### User prompt
```
In MailQueue, create "ReadMail.xaml" that uses GetIMAPMailMessages to connect to "imap.example.com" port 993 with SSL, user "bot@example.com", reads top 5 messages, and for each logs the subject line. Don't need it to actually connect — just validate 0 errors.
```

### Validation
- `get-errors` returns 0
- XAML has GetIMAPMailMessages with correct server/port/SSL config

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | IMAP activity configured, ForEach over messages, 0 errors |
| 8-9 | Works after fixing SecureConnection or Port property |
| 6-7 | IMAP configured but loop over messages has issues |
| 4-5 | Activity found but connection properties wrong |
| 2-3 | Couldn't find IMAP activity |
| 0-1 | No attempt |

---

## T39: Parallel ForEach

### User prompt
```
In MailQueue, create "ParallelProcess.xaml" that creates a list of 5 names: Alice, Bob, Carol, Dave, Eve. Uses ParallelForEach to process them — inside each branch, log "Processing: {name}" and add a Delay of 1 second. Log "All done" at the end. Just validate 0 errors (don't run — parallel + delay would be slow).
```

### Validation
- `get-errors` returns 0
- XAML uses `ParallelForEach` activity (not regular ForEach)

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | ParallelForEach with body activities, 0 errors |
| 8-9 | Works after fixing type arguments or Delay format |
| 6-7 | ParallelForEach found but body configuration needed fixes |
| 4-5 | Activity found but type errors |
| 2-3 | Couldn't find ParallelForEach |
| 0-1 | No attempt |

---

## T40: State Machine workflow

### User prompt
```
In MailQueue, create "ProcessOrder.xaml" as a State Machine with 3 states: "Received" (initial), "Processing", "Complete" (final). Transition from Received to Processing: log "Order received, starting processing". Transition from Processing to Complete: log "Processing done, order complete". The initial state should be Received. Just validate 0 errors.
```

### Validation
- `get-errors` returns 0
- XAML uses `<StateMachine>` root with 3 `<State>` elements and transitions

### Scoring
| Score | Criteria |
|-------|----------|
| 10 | State Machine with states, transitions, correct initial state |
| 8-9 | Works after fixing State/Transition configuration |
| 6-7 | States created but transitions have issues |
| 4-5 | StateMachine root but can't configure states |
| 2-3 | Fell back to Sequence (accepted but much lower score) |
| 0-1 | No attempt |

---

# Summary

| Project | Tests | Focus | Expression |
|---------|-------|-------|-----------|
| FileOps | T01-T04 | File I/O, folders, ZIP | VB |
| DataPipe | T05-T08 | CSV, DataTable, Lookup | VB |
| WebClient | T09-T12 | HTTP, JSON, C# expressions | **C#** |
| TextProcessor | T13-T16 | Regex, Dictionary, InvokeCode, types | VB |
| ExcelPro | T17-T19 | Multi-sheet, LINQ, write | VB |
| FlowLogic | T20-T23 | Flowchart, Switch, DoWhile, Retry | VB |
| ErrorMaster | T24-T26 | Multi-catch, nested TryCatch, Finally | VB |
| Orchestrator | T27-T29 | Config, In/Out/InOut args, multi-file | VB |
| PdfMaster | T30-T32 | PDF generate, read, merge | VB |
| CSharpEdge | T33-T36 | C# assigns, loops, TryCatch, Dictionary | **C#** |
| MailQueue | T37-T40 | Email, IMAP, Parallel, State Machine | VB |

**Total: 40 tests, 11 projects, 400 points max.**

**Coverage vs old test plan:**

| Gap | Now covered by |
|-----|---------------|
| File/folder operations | T01-T04 |
| CSV read/write | T05, T07 |
| DataTable manipulation | T06, T07, T08 |
| C# expression language | T09-T12, T33-T36 |
| Flowchart workflows | T20 |
| Switch/Case | T21 |
| Do While | T22 |
| Retry Scope | T23 |
| Multiple catch blocks | T24 |
| Nested TryCatch | T25 |
| Finally block | T26 |
| InvokeCode | T15, T23, T24, T25 |
| Dictionary usage | T14, T27, T36 |
| String/Regex patterns | T13, T14, T16 |
| Multi-workflow (3+ files) | T29 |
| InOut arguments | T28 |
| Config file pattern | T27 |
| PDF operations | T30-T32 |
| JSON construction | T10, T36 |
| Parallel ForEach | T39 |
| State Machine | T40 |
| IMAP mail | T38 |
| HTML email | T37 |
| Type conversions | T16 |
| LINQ GroupBy | T18 |
| LookupDataTable | T08 |
