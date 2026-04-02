# Validation and fixing

Read this file when: you are in the validate/fix loop and need detailed procedures for package resolution, JIT types, or debugging.

## Fix one thing at a time

When an error occurs, identify the root cause, fix **only** that one thing, and re-run.
- Never bundle a speculative improvement with the actual fix.
- One fix per iteration, re-run, verify.

## Validation iteration loop

After every file create or edit, validate until clean:

```
REPEAT:
  1. Run pre-flight validator (catches structural issues with clear fix instructions):
     powershell -ExecutionPolicy Bypass -File "{skillPath}/scripts/validate-xaml.ps1" -XamlPath "<ABSOLUTE_PATH>" -ProjectRoot "<PROJECT_ROOT>"
  2. IF pre-flight returns findings -> fix them FIRST (they have exact fix instructions), GOTO 1
  3. uip rpa get-errors --file-path "<RELATIVE_PATH>" --format json
  4. IF 0 errors -> EXIT to Smoke Test
  5. Identify the highest-priority error
  6. Fix one thing (see rule above)
  7. GOTO 1
```

The pre-flight validator catches: malformed XML, x:Class/file-path mismatch, expression language
conflicts, wrong type prefixes (x:DateTime -> s:DateTime), duplicate IdRefs, missing xmlns
declarations, mscorlib vs System.Private.CoreLib, missing TextExpression sections, and more.
Each finding includes a `fix` field with the exact action to take.

Cap at 5 fix attempts. After 5 failed attempts, present the remaining errors to the user.

### Rules

1. DO NOT stop until all errors are resolved (or cannot be resolved automatically).
2. DO NOT obsess on one error — if it cannot be resolved, skip it and defer to the user.
3. DO NOT skip validation steps.
4. DO NOT assume edits worked without checking.
5. DO NOT bundle multiple fixes in one iteration.

## Smoke test

After reaching 0 validation errors, run the workflow to catch runtime errors:

```bash
uip rpa run-file --file-path "<FILE>" --format json
```

When NOT to run: workflow has side effects (sends emails, modifies databases), requires interactive input, or compilation errors still exist.

Stop after 2 failed runtime retries and present the error to the user.

## Package error resolution

```bash
# Check current dependencies:
Read: file_path="{projectRoot}/project.json"

# Install or update (omit version for latest):
uip rpa install-or-update-packages --packages '[{"id": "UiPath.Excel.Activities"}]' --format json
```

If `install-or-update-packages` fails:
- Package not found: verify the exact package ID with `uip rpa find-activities`.
- Network/feed error: user may need to check NuGet feed configuration in Studio settings.

## Resolving dynamic activity custom types

After adding a dynamic activity (connector) via `get-default-activity-xaml`, read the JIT custom types schema to discover property names and CLR types:

```
Read: file_path="{projectRoot}/.project/JitCustomTypesSchema.json"
```

See [jit-custom-types-schema.md](jit-custom-types-schema.md) for the full schema structure and type mapping.

## Focus activity for debugging

When `get-errors` returns an error referencing a specific activity, use `focus-activity` to highlight it in Studio:

```bash
uip rpa focus-activity --activity-id "Assign_1" --format json
```

## Fix order

1. **Package errors**: missing namespace, unknown activity type. Install/update the package.
2. **Structural errors**: invalid XML, missing closing tags. Read and edit the XAML.
3. **Type errors**: wrong property type, invalid cast. Check activity docs for correct types.
4. **Property errors**: unknown properties, misconfigured groups. Check activity docs or `get-default-activity-xaml`.
5. **Logic errors**: wrong behavior, incorrect expressions. Read XAML and correct. Use `run-file` for runtime validation.

## When stuck

- Defer minor configuration details to the user (connections, placeholder values).
- If an activity has unresolvable issues, consider `InvokeCode` as a last resort.
- Do not retry the same fix more than 3 times. Explain the error to the user.
