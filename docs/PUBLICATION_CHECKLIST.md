# Publication Checklist

Run these from the repository root before pushing publicly.

1. Create a topic branch. Do not push directly to `main`.

```bash
git checkout -b your-change-name
```

2. Confirm there are no private staging folders:

```bash
find . -name .git -type d -prune -print
find . -name '*.lock' -o -name '.DS_Store'
```

3. Run the bundled publish check:

```bash
bash scripts/publish-check.sh
```

4. Check for personal identifiers:

```bash
rg -n --hidden 'your-real-email@example.com|/Users/yourname|phone|token|password' .
```

5. Review `.security-allowlist` manually. Every entry should be narrow and
explainable.

6. Confirm any `.env`, session, credential, backup, and local profile files are
excluded by `.gitignore`.

7. Open a pull request.
