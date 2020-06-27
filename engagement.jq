(select(.stat == "pr_lifetime_summary").data | map( {(.group) : .data }) | add |
{
    "PRs": .ANOVA.N,
    "Merged PRs": .merged.N,
    "Closed PRs": .closed.N,
    "Merged avg (hrs)": (.merged.mean / 3600),
    "Merged p50 (hrs)": (.merged.p50 / 3600),
    "Merged p75 (hrs)": (.merged.p75 / 3600),
    "Merged p95 (hrs)": (.merged.p95 / 3600),
    "Closed avg (hrs)": (.closed.mean / 3600),
    "Closed p50 (hrs)": (.closed.p50 / 3600),
    "Closed p75 (hrs)": (.closed.p75 / 3600),
    "Closed p95 (hrs)": (.closed.p95 / 3600)
}),
(select(.stat == "pr_comment_summary").data | map( {(.group) : .data }) | add |
{
    "merged comments mean": ."merged-allcommentswzero".mean,
    "merged comments p50": ."merged-allcommentswzero".p50,
    "merged comments p75": ."merged-allcommentswzero".p75,
    "merged comments p95": ."merged-allcommentswzero".p95,
    "closed comments mean": ."closed-allcommentswzero".mean,
    "closed comments p50": ."closed-allcommentswzero".p50,
    "closed comments p75": ."closed-allcommentswzero".p75,
    "closed comments p95": ."closed-allcommentswzero".p95
}),
(select(.stat == "gh_merges_during_prs").data),
(select(.stat == "commits_per_pr").data | map( {(.group) : .data }) | add |
{
    "commits per merged mean": .merged.mean,
    "commits per merged p50": .merged.p50,
    "commits per merged p75": .merged.p75,
    "commits per closed mean": .closed.mean,
    "commits per closed p50": .closed.p50,
    "commits per closed p75": .closed.p75
}),
(select(.stat == "pr_time_per_pr_wzero").data | map( {(.group) : .data }) | add |
{
    "merged active time estimate mean (hrs)": (."merged-estimate".mean / 3600),
    "merged active time estimate p50 (hrs)": (."merged-estimate".p50 / 3600),
    "merged active time estimate p75 (hrs)": (."merged-estimate".p75 / 3600),
    "merged active time estimate p95 (hrs)": (."merged-estimate".p95 / 3600),
    "closed active time estimate mean (hrs)": (."closed-estimate".mean / 3600),
    "closed active time estimate p50 (hrs)": (."closed-estimate".p50 / 3600),
    "closed active time estimate p75 (hrs)": (."closed-estimate".p75 / 3600),
    "closed active time estimate p95 (hrs)": (."closed-estimate".p95 / 3600)
}),
(select(.stat == "commit_relative_age").data | map( {(.group) : .data }) | add |
{
    "commit merged rel age mean (hrs)": (.merged.mean / 3600),
    "commit merged rel age p50 (hrs)": (.merged.p50 / 3600),
    "commit merged rel age p75 (hrs)": (.merged.p75 / 3600),
    "commit closed rel age mean (hrs)": (.closed.mean / 3600),
    "commit closed rel age p50 (hrs)": (.closed.p50 / 3600),
    "commit closed rel age p75 (hrs)": (.closed.p75 / 3600)
})

