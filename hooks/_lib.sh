# shellcheck shell=sh

# run_local_hook NAME [ARGS...] replaces the current process with the
# repository's own hook NAME, when it exists and is executable, and otherwise
# exits 0.
run_local_hook() {
    name=$1
    shift

    # Not --git-path hooks: that follows core.hooksPath, which is us. The common
    # dir also covers linked worktrees, which share the main checkout's hooks.
    git_dir=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
    hooks_dir="$git_dir/hooks"
    local_hook="$hooks_dir/$name"

    # Never run ourselves, should .git/hooks be a link to this directory.
    global_dir=$(cd "$(dirname "$0")" && pwd -P)
    if [ -d "$hooks_dir" ] && [ "$(cd "$hooks_dir" && pwd -P)" = "$global_dir" ]; then
        exit 0
    fi

    if [ -x "$local_hook" ]; then
        exec "$local_hook" "$@"
    fi

    exit 0
}
