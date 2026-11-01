# git-hooks-global

Git hooks for every repository on this machine, through the global `core.hooksPath`.

## Hooks

- **`commit-msg`** rejects a commit message that credits an AI assistant: a `Co-Authored-By:` line naming
  Claude or Anthropic, any `noreply@anthropic.com` address, or a "Generated with … Claude" line. Comment lines
  and the diff `git commit -v` appends are ignored. `git commit --no-verify` skips it.
- **Every other client hook** links to `_passthrough`.

A global `core.hooksPath` makes git skip a repository's own `.git/hooks`. So every hook here, `commit-msg`
included once its check passes, then runs the repository's hook of the same name, if there is one, with the
same arguments and stdin. Linked worktrees use the main checkout's hooks, as git does.

A repository that sets its own `core.hooksPath` (husky does) overrides the global one, so these hooks do not
run there.

## Install

```shell
task install     # git config --global core.hooksPath <this checkout>/hooks
task uninstall   # unsets it, only if it points here
```

`task install` refuses to overwrite a `core.hooksPath` that points elsewhere.

## Test

```shell
task test
```

The tests use throwaway repositories with a repository-level `core.hooksPath`; the global config is never
touched.
