#!/usr/bin/awk

#compute N, min, 0.05, .25, .5, .75, 0.95, max, mean, stdev

#assume we can store everything in memory

function printstats(key, data, countvals, sumvals, sumsquares) {
    asort(data);
    printf("%s\tN\t%d\n", key, countvals);
    printf("%s\tmin\t%f\n", key, data[1]);
    printf("%s\tp05\t%f\n", key, data[int(countvals*0.05)+1]);
    printf("%s\tp25\t%f\n", key, data[int(countvals*0.25)+1]);
    printf("%s\tp50\t%f\n", key, data[int(countvals*0.5)+1]);
    printf("%s\tp75\t%f\n", key, data[int(countvals*0.75)+1]);
    printf("%s\tp95\t%f\n", key, data[int(countvals*0.95)+1]);
    printf("%s\tmax\t%f\n", key, data[countvals]);
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

{
    ss[$1] += $2*$2;
    s[$1] += $2;
    n[$1] += 1;
    d[$1][n[$1]] = $2;
    all_SS += $2*$2;
    all_S += $2;
    all_n += 1;
    all_d[all_n] = $2;
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
                #TODO: would be better to not pass over the data again
                for (j in d[x]) {
                    unexplained_variance += (d[x][j] - Ybar_i[x])*(d[x][j] - Ybar_i[x]) / (N-K);
                }
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
