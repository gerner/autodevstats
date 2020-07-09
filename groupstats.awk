#!/usr/bin/awk

#compute N, min, 0.05, .25, .5, .75, 0.95, max, mean, stdev

function sq_init(sq, epsilon, compact_size) {
    sq["epsilon"] = epsilon;
    sq["k"] = compact_size;
    sq["n"] = 0;
    sq["W"] = exp(log(rand())/compact_size);
    sq["next_i"] = compact_size + int(log(rand())/log(1-sq["W"])) + 1;
    sq["min"] = "";
    sq["max"] = "";
}

function sq_insert(sq, v, _i) {
    if(sq["n"] < sq["k"]) {
        #take the first k elements
        sq["s"][sq["n"]+1] = v;
        if(sq["min"] == "") {
            sq["min"] = v;
        } else {
            sq["min"] = (sq["min"]<v)?sq["min"]:v;
        }
        if(sq["max"] == "") {
            sq["max"] = v;
        } else {
            sq["max"] = (sq["max"]>v)?sq["max"]:v;
        }

    } else {
        if(sq["n"] == sq["next_i"]) {
            sq["s"][int(rand()*sq["k"])+1] = v;
            sq["W"] = sq["W"] * exp(log(rand())/sq["k"])
            sq["next_i"] = sq["next_i"] + int(log(rand())/log(1-sq["W"])) + 1;
        }
        sq["min"] = (sq["min"]<v)?sq["min"]:v;
        sq["max"] = (sq["max"]>v)?sq["max"]:v;

    }
    sq["n"] += 1;
}


function sq_quantile(sq, phi, _i) {
    _i = int(phi*((sq["n"]<sq["k"])?sq["n"]:sq["k"]));
    return sq["s"][_i];
}

function sq_min(sq) {
    return sq["min"];
}

function sq_max(sq) {
    return sq["max"];
}

function printstats(key, data, countvals, sumvals, sumsquares) {
    asort(data["s"]);
    printf("%s\tN\t%d\n", key, countvals);
    printf("%s\tmin\t%f\n", key, sq_min(data));
    printf("%s\tp05\t%f\n", key, sq_quantile(data,0.05));
    printf("%s\tp25\t%f\n", key, sq_quantile(data,0.25));
    printf("%s\tp50\t%f\n", key, sq_quantile(data,0.5));
    printf("%s\tp75\t%f\n", key, sq_quantile(data,0.75));
    printf("%s\tp95\t%f\n", key, sq_quantile(data,0.95));
    printf("%s\tmax\t%f\n", key, sq_max(data));
    printf("%s\tmean\t%f\n", key, sumvals/countvals);

    if(sumsquares < sumvals*sumvals/countvals) {
        #protect against numerical stability issues
        stdev=-1;
    } else if(countvals <= 1) {
        #protect against an edgecase with just one element
        #if there are zero elements than x won't exist in s
        stdev=0;
    } else {
        stdev=sqrt((sumsquares-sumvals*sumvals/countvals)/(countvals-1));
    }
    printf("%s\tstdev\t%f\n", key, stdev);
}

NF != 2 {
    print "didn't have two fields on line", NR, "fields", NF, "line", $0 > "/dev/stderr"
    exit 1;
}

BEGIN {
    delete all_d;
    sq_init(all_d, 0.05, 10000);
}

!n[$1] {
    d[$1]["min"];
    sq_init(d[$1], 0.05, 10000);
}

{
    ss[$1] += $2*$2;
    s[$1] += $2;
    n[$1] += 1;
    sq_insert(d[$1], $2);
    all_SS += $2*$2;
    all_S += $2;
    all_n += 1;
    sq_insert(all_d, $2);
    N+=1;
}

END {
    if(N>0) {
        K=0;
        Ysum=0;
        for(x in s) {
            printstats(x, d[x], n[x], s[x], ss[x]);

            K+=1;
            Ybar[x] = s[x]/n[x];
            Ysum += s[x];
        };

        printstats("ALL", all_d, all_n, all_S, all_SS);

        if(K>1 && N > K) {
            explained_variance=0;
            for(x in Ybar) {
                explained_variance += n[x]*(Ybar[x] - Ysum/N)*(Ybar[x] - Ysum/N)/(K-1);
            }
            unexplained_variance=0;
            for(x in Ybar) {
                unexplained_variance += (ss[x] - s[x]*s[x]/n[x])/(N-K);
                #TODO: would be better to not pass over the data again
                #for (j in d[x]) {
                #    unexplained_variance += (d[x][j] - Ybar_i[x])*(d[x][j] - Ybar_i[x]) / (N-K);
                #}
            }

            if(unexplained_variance > 0) {
                F = explained_variance / unexplained_variance;
            } else {
                F = 0;
            }

            printf("ANOVA\tF\t%f\n", F);
            printf("ANOVA\td1\t%d\n", K-1);
            printf("ANOVA\td2\t%d\n", N-K);
            printf("ANOVA\tK\t%d\n", K);
            printf("ANOVA\tN\t%d\n", N);
            printf("ANOVA\tev\t%f\n", explained_variance);
            printf("ANOVA\tuv\t%f\n", unexplained_variance);
            printf("ANOVA\tgrandmean\t%f\n", Ysum/N);
        }
    }
}
