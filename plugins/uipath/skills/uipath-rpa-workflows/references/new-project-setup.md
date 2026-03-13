# Creating New Projects

When the user needs a brand-new UiPath project (not just a new workflow in an existing project):

```bash
uipcli rpa new \
  --name "MyAutomation" \
  --location "/path/to/parent/directory" \
  --template-id "BlankTemplate" \
  --expression-language "VisualBasic" \
  --target-framework "Windows" \
  --description "Automates invoice processing" \
  --format json
```

## Parameters

| Parameter | Options | Default | Notes |
|-----------|---------|---------|-------|
| `--name` | Any string | (required) | Project folder name |
| `--location` | Directory path | (current dir) | Parent directory where project folder is created |
| `--template-id` | `BlankTemplate`, `LibraryProcessTemplate`, `TestAutomationProjectTemplate` | `BlankTemplate` | Project template |
| `--expression-language` | `VisualBasic`, `CSharp` | (template default) | Expression syntax for XAML workflows |
| `--target-framework` | `Legacy`, `Windows`, `Portable` | (template default) | .NET target framework |
| `--description` | Any string | (none) | Project description in project.json |

## After Creation

1. Open the project in Studio: `uipcli rpa open-project --project-dir "/path/to/MyAutomation"`
2. The project root is now `/path/to/parent/directory/MyAutomation/`
3. Proceed to Phase 1 (Discovery) using the new project root
