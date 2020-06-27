#!/usr/bin/awk

#compute N, min, 0.05, .25, .5, .75, 0.95, max, mean, stdev

#assume we can store everything in memory

BEGIN {
    n=0;
}

{
    ss += $1*$1;
    s += $1;
    n += 1;
    d[n] = $1;
}

END {
    if(n > 0) {
        asort(d,sorted_d);
        printf("N\t%d\n", n);
        printf("min\t%f\n", sorted_d[1]);
        printf("0.05\t%f\n", sorted_d[int(NR*0.05)+1]);
        printf("0.25\t%f\n", sorted_d[int(NR*0.25)+1]);
        printf("0.5\t%f\n", sorted_d[int(NR*0.5)+1]);
        printf("0.75\t%f\n", sorted_d[int(NR*0.75)+1]);
        printf("0.95\t%f\n", sorted_d[int(NR*0.95)+1]);
        printf("max\t%f\n", sorted_d[n]);
        printf("mean\t%f\n", s/n);


        #protect against an edgecase with just one element
        if(n == 1) {
            stdev=0;
        } else {
            stdev=sqrt((ss-s*s/n)/(n-1));
        }
        printf("stdev\t%f\n", stdev);
    } else {
        printf("N\t%d\n", n);
    }
}
