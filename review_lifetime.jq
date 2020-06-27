(select(.stat == "commit_review_vs_date").data | map( {(.group) : .data }) | add |
    {
        "date ANOVA": .ANOVA.F,
        "mean diff (days)":((.reviewed.mean - .unreviewed.mean) / 3600 / 24),
        "median diff (days)": ((.reviewed.p50 - .unreviewed.p50) / 3600 / 24),
        "rev N": .reviewed.N,
        "unrev N": .unreviewed.N
    }
),
(select(.stat == "commit_review_file_overlap").data | map( {(.group) : .data }) | add |
    {
        "unweighted jaccard index": .UNWEIGHTED_JACCARD.index,
        "weighted jaccard index": .WEIGHTED_JACCARD.index
    }
),
(select(.stat == "commit_review_vs_lifetime").data | map( {(.group) : .data }) | add |
    {
        "lifetime ANOVA": .ANOVA.F,
        "mean diff (days)": ((.reviewed.mean-.unreviewed.mean)/3600/24),
        "median diff (days)": ((.reviewed.p50-.unreviewed.p50)/3600/24),
        "rev mean (days)": (.reviewed.mean / 3600 / 24),
        "rev median (days)": (.reviewed.p50 / 3600 / 24),
        "rev N": .reviewed.N,
        "unrev N": .unreviewed.N
    }
)
