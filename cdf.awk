FNR == 1 {
    fileindex += 1;
}

fileindex == 1 {
    X[FNR] = $1;
}

ENDFILE {
    if(fileindex == 1) {
        asort(X);
        Xi = 1;
        Xn = FNR;
    }
}

fileindex == 2 && FNR == 1 {
    minval = $1;
    if(minval >= X[1]) {
        passedmin = 1;
    }
}

fileindex == 2 && !passedmin && $1 > minval {
    printf("%s\t%d\n", minval, FNR-1);
    passedmin = 1;
}

fileindex == 2 {
    while(Xi < Xn && $1 > X[Xi]) {
        printf("%s\t%d\n", X[Xi], FNR-1);
        Xi+=1;
    }
    if(Xi == Xn && $1 > X[Xi]) {
        printf("%s\t%d\n", X[Xi], FNR-1);
        Xi+=1;
    }
    last = $1;
}

END {
    while(Xi <= Xn) {
        printf("%s\t%d\n", X[Xi], FNR);
        Xi+=1;
    }
    #handle case where the max element is larger than scale
    if(last > X[Xn]) {
        printf("%s\t%d\n", last, FNR);
    }
}
