#!/bin/sh
# Exercises the hooks in throwaway repositories, with core.hooksPath set per
# repository so the global git config is never touched.
set -u

hooks_dir=$(cd "$(dirname "$0")/../hooks" && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0

pass() { echo "ok   $1"; }
fail() {
    echo "FAIL $1"
    failures=$((failures + 1))
}

new_repo() {
    repo="$tmp/$1"
    git init -q "$repo"
    git -C "$repo" config core.hooksPath "$hooks_dir"
    git -C "$repo" config user.name test
    git -C "$repo" config user.email test@example.com
    git -C "$repo" config commit.gpgsign false
}

# commit REPO MESSAGE [ARGS...] makes a commit and returns git's exit status.
commit() {
    c_repo=$1
    c_message=$2
    shift 2
    date +%s%N >>"$c_repo/file"
    git -C "$c_repo" add file
    git -C "$c_repo" commit -q -m "$c_message" "$@" >/dev/null 2>&1
}

new_repo attribution
r="$tmp/attribution"

for message in \
    "$(printf 'Fix it\n\nCo-Authored-By: Claude <noreply@anthropic.com>')" \
    "$(printf 'Fix it\n\nco-authored-by: Claude Opus 4 <x@example.com>')" \
    "$(printf 'Fix it\n\nCo-Authored-By: Someone <noreply@anthropic.com>')" \
    "$(printf 'Fix it\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)')"; do
    if commit "$r" "$message"; then
        fail "rejects: $(echo "$message" | tail -1)"
    else
        pass "rejects: $(echo "$message" | tail -1)"
    fi
done

for message in \
    "Fix the parser" \
    "$(printf 'Fix it\n\nCo-Authored-By: Jane <jane@example.com>')" \
    "Mention Claude Shannon in the docs"; do
    if commit "$r" "$message"; then
        pass "accepts: $(echo "$message" | tail -1)"
    else
        fail "accepts: $(echo "$message" | tail -1)"
    fi
done

if commit "$r" "$(printf 'Fix it\n\nCo-Authored-By: Claude <noreply@anthropic.com>')" --no-verify; then
    pass "--no-verify bypasses the check"
else
    fail "--no-verify bypasses the check"
fi

# The repository's own hooks still run.
new_repo local
r="$tmp/local"
printf '#!/bin/sh\necho pre-commit-ran >>"%s/ran"\n' "$tmp" >"$r/.git/hooks/pre-commit"
# shellcheck disable=SC2016 # $1 is for the generated hook, not this script.
printf '#!/bin/sh\necho "commit-msg-ran $1" >>"%s/ran"\ngrep -q WIP "$1" && exit 1\nexit 0\n' "$tmp" >"$r/.git/hooks/commit-msg"
chmod +x "$r/.git/hooks/pre-commit" "$r/.git/hooks/commit-msg"

if commit "$r" "Fix it" && grep -q pre-commit-ran "$tmp/ran" && grep -q commit-msg-ran "$tmp/ran"; then
    pass "runs the repository's own pre-commit and commit-msg"
else
    fail "runs the repository's own pre-commit and commit-msg"
fi

if commit "$r" "WIP"; then
    fail "the repository's own commit-msg can still reject"
else
    pass "the repository's own commit-msg can still reject"
fi

# A linked worktree uses the main checkout's hooks.
git -C "$r" worktree add -q "$tmp/wt" 2>/dev/null
rm -f "$tmp/ran"
if commit "$tmp/wt" "Fix it in a worktree" && grep -q pre-commit-ran "$tmp/ran"; then
    pass "runs the repository's hooks from a linked worktree"
else
    fail "runs the repository's hooks from a linked worktree"
fi

# A hook that reads stdin gets it.
printf '#!/bin/sh\ncat >"%s/stdin"\n' "$tmp" >"$r/.git/hooks/post-rewrite"
chmod +x "$r/.git/hooks/post-rewrite"
if git -C "$r" commit -q --amend -m "Fix it, amended" >/dev/null 2>&1 && [ -s "$tmp/stdin" ]; then
    pass "passes stdin through (post-rewrite)"
else
    fail "passes stdin through (post-rewrite)"
fi

# No local hook: nothing to run, nothing fails.
new_repo bare
if commit "$tmp/bare" "Fix it"; then
    pass "succeeds without local hooks"
else
    fail "succeeds without local hooks"
fi

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures failed"
    exit 1
fi

echo "all passed"
