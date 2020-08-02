#assume input is sorted in topological order
#format, tab separated:
#1. commit hash
#2. PR number (or empty string if no PR assigned)
#3. committer email
#4. committer timestamp
#5. author email
#6. topological order number

#if we ever transition to a new committer or timestamp, clear last_pr
$3 != last_ce || $4 != last_ct {
    last_pr = "";
}

$2 != "" {
    #if there is a merge commit, keep it
    printf("%s\t%s\n", $1, $2);

    #if we've moved on to a different committer/timestamp
    #we will only cascade the first PR we see in a run of last_ce/ct
    #this allows nested reviews within an outer review
    #e.g. in the case of a merge of a dev branch with a bunch of PRs into
    #mainline, while avoiding mis-attributing review
    if($3 != last_ce || $4 != last_ct) {
        last_pr=$2;last_ce=$3;last_ct=$4;
    }
}

$2 == "" {
    if($3 == last_ce && $4 == last_ct && last_pr != "") {
        printf("%s\t%s\n", $1, last_pr);
    }
}
