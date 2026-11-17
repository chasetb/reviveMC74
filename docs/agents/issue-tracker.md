# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues in `chasetb/reviveMC74`. Use the `gh` CLI for all operations.

This checkout's `gh` default selects the upstream repo, so pass `--repo chasetb/reviveMC74` to `gh issue` and `gh pr` commands. For `gh api`, use `repos/chasetb/reviveMC74/...`.

## Conventions

- **Create an issue**: `gh issue create --repo chasetb/reviveMC74 --title "..." --body "..."`
- **Read an issue**: `gh issue view <number> --repo chasetb/reviveMC74 --json number,title,body,labels,comments`
- **List issues**: `gh issue list --repo chasetb/reviveMC74 --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Make an issue a sub-issue of a parent**: `gh issue create --repo chasetb/reviveMC74 --parent <parent> ...`, or `gh issue edit <parent> --repo chasetb/reviveMC74 --add-sub-issue <child>` afterwards (`gh` 2.94+). Older `gh`: `gh api --method POST repos/chasetb/reviveMC74/issues/<parent>/sub_issues -F sub_issue_id=<child-db-id>` (database id, as in **Blocking** below). Without sub-issues, put `Part of #<parent>` at the top of the child body.
- **Blocking**: GitHub's **native issue dependencies**, the canonical, UI-visible representation. Add an edge with `gh issue create --repo chasetb/reviveMC74 --blocked-by <n>,<n> ...` or `gh issue edit <child> --repo chasetb/reviveMC74 --add-blocked-by <blocker>` (`gh` 2.94+). Older `gh`: `gh api --method POST repos/chasetb/reviveMC74/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/chasetb/reviveMC74/issues/<n> --jq .id`, not the `#number` or `node_id`). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Count open blockers**: `gh api repos/chasetb/reviveMC74/issues/<n> --jq .issue_dependencies_summary.blocked_by` (open blockers only; 0 means startable). `gh issue view <n> --repo chasetb/reviveMC74 --json blockedBy` also lists closed blockers, so filter it: `--jq '[.blockedBy.nodes[] | select(.state == "OPEN")] | length'`.
- **Comment on an issue**: `gh issue comment <number> --repo chasetb/reviveMC74 --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --repo chasetb/reviveMC74 --add-label "..."` / `--remove-label "..."`
- **Close**: post the explanation with `gh issue comment <number> --repo chasetb/reviveMC74 --body "..."`, then `gh issue close <number> --repo chasetb/reviveMC74`. On an already-closed issue, `gh issue close --comment` drops the comment and still exits 0.

File issues only into the user's own repo, `chasetb/reviveMC74`, never into `mattpocock/skills` unless the user owns it. This checkout has an upstream parent; verify the target with `gh repo view chasetb/reviveMC74 --json nameWithOwner` before the first issue write.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --repo chasetb/reviveMC74`, then `gh pr view <number> --repo chasetb/reviveMC74 --comments` (off a TTY, `--comments` prints only the comments, not the body), and `gh pr diff <number> --repo chasetb/reviveMC74` for the diff.
- **List external PRs for triage**: `gh api --paginate 'repos/chasetb/reviveMC74/pulls?state=open' --jq '.[] | select(.author_association | IN("OWNER","MEMBER","COLLABORATOR") | not) | {number, title, author: .user.login, author_association, labels: [.labels[].name]}'`.
- **Comment / label / close**: use `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, and `gh pr close`, each with `--repo chasetb/reviveMC74`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view 42 --repo chasetb/reviveMC74` and fall back to `gh issue view 42 --repo chasetb/reviveMC74`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. `gh issue create --repo chasetb/reviveMC74 --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (see **Make an issue a sub-issue of a parent**). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: see **Blocking** under Conventions.
- **Frontier query**: list the map's open children (`gh issue list --repo chasetb/reviveMC74 --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (see **Count open blockers**, or an open issue in the `Blocked by` line) or an assignee; first in map order wins.
- **Claim**: `gh issue edit <n> --repo chasetb/reviveMC74 --add-assignee @me`, the session's first write.
- **Resolve**: `gh issue comment <n> --repo chasetb/reviveMC74 --body "<answer>"`, then `gh issue close <n> --repo chasetb/reviveMC74`, then append a context pointer (gist + link) to the map's Decisions-so-far.
