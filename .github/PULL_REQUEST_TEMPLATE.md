## What this changes

<one-paragraph summary>

## Motivation

<why is this needed?>

## Type of change

- [ ] Bug fix (non-breaking)
- [ ] Feature (non-breaking)
- [ ] Breaking change (requires CHANGELOG note + version bump)
- [ ] Documentation only
- [ ] Refactor / cleanup

## Checklist

- [ ] I read [CONTRIBUTING.md](../CONTRIBUTING.md)
- [ ] No secrets in any committed file
- [ ] No hard-coded `/home/<user>` paths — `$HOME` or `~` only
- [ ] Tested locally: `bash install.sh --dry-run user`
- [ ] Conventional commit message
- [ ] Updated relevant docs (`README.md`, `user/docs/*.md`, `CHANGELOG.md`)
- [ ] Idempotent — running twice doesn't break

## Validation

```
<paste output of secret scan + path leak scan>
grep -rEI 'sk-[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{20,}' .   # nothing
grep -rEI '/home/[a-z]+/' .                                  # nothing
```

## Screenshots / output (if applicable)

<paste before/after if behaviour changes>
