
#run with included date.awk and reduce.awk

#input: comments sorted by PR, dev, create time
#columns:
#1. PR number
#2. dev login
#3. create time of comment (in ISO-8601)
#4. type of comment (e.g. toplevel, codecomment)
#5. state of pr (assume it's the same for all rows within pr)

#output: comments including which "dev-ply" the comment belongs to
#columns:
#1. PR number
#2. dev login
#3. ply number
#4. create time of comment (unix timestamp)
#5. type of comment (e.g. toplevel, codecomment)
#6. state of pr
#7. create time of pr (unix timestamp)
#8. close time of pr (unix timestamp) (if there is one)


BEGIN {
    OFS="\t";
    setkey("1\t2");
}

function startrun(key) {
    lastts=parsedate($3);
    cycles=0;
}

function reduce(key) {
    ts=parsedate($3);
    #bail if this comment happened after the PR was closed
    if($7 == "") {
        closets="";
    } else {
        closets=parsedate($7);
        #if(ts > closets) {
        #    return;
        #}
    }

    if(ts - lastts > 2*3600) {
        cycles+=1;
    };

    createts=parsedate($6);

    #output one row for every comment including which cycle it belongs to
    print $1,$2,cycles,ts, $4, $5, createts, closets;
    lastts=ts;
}

function endrun(key) { }
