# Self-Review Checklist

Before delivering ANY code:

1. **Run it.** Don't assume it works.
2. **Test bad input.** Empty strings, None, missing files, huge data.
3. **Scan for secrets.** `grep -rE "(sk-ant-|nvapi-|password\s*=)" .`
4. **Verify imports.** AI hallucinates ~20% of package names. Run `pip show PKG` or `npm list PKG`.
5. **Run tests.** If none exist, test manually with at least 3 cases.
6. **Match style.** Read 3 adjacent files. Match naming and patterns.

## Common Mistakes
- Hardcoded paths: `grep -r '/Users/' .`
- Debug code: `grep -r 'print(\|console.log\|breakpoint' .`
- Broad exceptions: `except Exception` hides bugs — catch specific errors
- Placeholder text: `grep -rn 'TODO\|FIXME\|HACK\|XXX' .`
- Missing type hints on Python functions
- Unclosed resources — use context managers
