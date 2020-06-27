BEGIN {
    OFS="\t";
    setkey("1");
}

function startrun(key) {
    delete vals;
}

function reduce(key) {
    if($3 == "") {
        $3 = 1;
    } else if($3 < 0) {
        print "got negative weight", $3, "for", $2, "on", NR > "/dev/stderr";
        error=1;
        exit 1;
    }
    vals[$2] += $3;
    sum_weight[$2] += $3;
}

function endrun(key) {
    if(length(vals) > 2) {
        print "got more than two groups for", key, "run ending on", NR-1 > "/dev/stderr";
        error=1;
        exit 1;
    }
    ni = "";
    di = "";
    for(x in vals) {
        if(ni == "") {
            ni = vals[x];
            di = vals[x];
        } else {
            ni = (vals[x] < ni)?vals[x]:ni;
            di = (vals[x] > di)?vals[x]:di;
        }
        keys[x] += 1;
    }
    if(length(vals) == 1) {
        ni = 0;
        uwni = 0;
    } else { #length(vals) == 2
        uwni = 1;
    }

    numerator += ni;
    denominator += di;
    vector_size += 1;

    uwnumerator += uwni;
    uwdenominator += 1;
}

END {
    if(!error) {
        for(x in keys) {
            printf("%s\tnon-zero weights\t%d\n", x, keys[x]);
            printf("%s\tmean_nonzero_weight\t%f\n", x, sum_weight[x]/keys[x]);
            printf("%s\tmean_weight\t%f\n", x, sum_weight[x]/vector_size);
            printf("%s\tsum_weight\t%f\n", x, sum_weight[x]);
        }

        if(denominator > 0) {
            printf("WEIGHTED_JACCARD\tindex\t%f\n", numerator/denominator);
            printf("WEIGHTED_JACCARD\tnumerator\t%f\n", numerator);
            printf("WEIGHTED_JACCARD\tdenominator\t%f\n", denominator);
            printf("WEIGHTED_JACCARD\tvector_size\t%f\n", vector_size);
        }

        if(uwdenominator > 0) {
            printf("UNWEIGHTED_JACCARD\tindex\t%f\n", uwnumerator/uwdenominator);
            printf("UNWEIGHTED_JACCARD\tnumerator\t%f\n", uwnumerator);
            printf("UNWEIGHTED_JACCARD\tdenominator\t%f\n", uwdenominator);
        }
    }
}
