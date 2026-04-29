# Publication Checklist

Run these from the repository root before pushing publicly.

1. Confirm there are no private staging folders:

```bash
find . -name .git -type d -prune -print
find . -name '*.lock' -o -name '.DS_Store'
```

2. Run the bundled publish check:

```bash
bash scripts/publish-check.sh
```

3. Check for personal identifiers:

```bash
rg -n --hidden 'your-real-email@example.com|/Users/yourname|phone|token|password' .
```

4. Review `.security-allowlist` manually. Every entry should be narrow and
explainable.

5. Confirm any `.env`, session, credential, backup, and local profile files are
excluded by `.gitignore`.
