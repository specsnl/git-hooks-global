# git-hooks-global

Git hooks installed for every repository on a machine through the global `core.hooksPath`. What the hooks do,
and how they hand over to a repository's own hooks, is in the [README](README.md).

## Commands

**Every command runs through [Task](https://taskfile.dev).** shellcheck and markdownlint run in Docker with the
versions pinned in the Taskfiles, which are the versions CI runs.

| Command          | What it does                                                  |
|------------------|---------------------------------------------------------------|
| `task checkall`  | Every check CI runs: shellcheck, the hook tests, markdownlint |
| `task lint`      | shellcheck over the hooks and tests                           |
| `task test`      | The hook tests (`tests/run.sh`), in throwaway repositories    |
| `task md:check`  | markdownlint over every Markdown file                         |
| `task md:fix`    | Align Markdown tables, then apply autofixable rules           |
| `task install`   | Point the global `core.hooksPath` at this checkout's `hooks/` |
| `task uninstall` | Unset the global `core.hooksPath`, if it points here          |

Run `task checkall` before pushing; it mirrors CI.

## Conventions

- **The hooks are POSIX `sh`.** They run on macOS (BSD userland) and Linux (GNU), and CI tests both; avoid
  bashisms and GNU-only flags.
- **The tests never touch the global git config.** They set `core.hooksPath` per throwaway repository.
- **A new hook name links to `_passthrough`.** A hook that checks something sources `_lib.sh` and ends with
  `run_local_hook`, so the repository's own hook still runs. Add it to `SHELL_FILES` in `Taskfile.dist.yml`
  and to the shellcheck step in `.github/workflows/ci.yml`.
- **Behaviour changes come with tests** in `tests/run.sh` and, when user-facing, a README update.
