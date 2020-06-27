BEGIN {
    OFS="\t"
}

{
    patsplit(tolower($0), a, /((close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) )?#[0-9]+/);
    for(x in a) {
        match(a[x], /([^#]*) ?#([0-9]+)/, m);
        if(m[1] == "") {
            print $1, m[2], dsname, "naked";
        } else {
            print $1, m[2], dsname, m[1];
        }
        print $1, m[2], dsname, "any"
    }
}
