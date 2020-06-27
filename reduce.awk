#########################################
# Handy Reduce Framework for Awk
#
# users must:
# call setkey in BEGIN with a string of column numbers separated by FS
#   these represent the key columns
#   e.g. setkey("1\t2\t3")
#       sets the key columns to 1,2,3
#       assumes FS matches tab
# define startrun function(key)
#   key param is the key for the run
#   called once per run on the first line of a run
# define reduce(key) function
#   key param is the key for the run
#   called once per line
# define endrun(key) function
#   key param is the key for the run
#   called once per run after the last line of a run
#
# reserves variables KEYCOLS and LASTKEY
# defines two functions
#   setkey (described above)
#   keymatches (internal function used to check if current line is part of
#       current run)

function setkey(keystr) {
    n=split(keystr, KEYCOLS);
    if(n < 1) {
        print "error splitting keystr \"" keystr "\" into parts" > "/dev/stderr";
        exit 1;
    }
}

function keymatches() {
    for(i in KEYCOLS) {
        if($KEYCOLS[i] != LASTKEY[i]) {
            return 0;
        }
    }
    return 1;
}

BEGIN {
}

{
    if(NR == 1) {
        for(i in KEYCOLS) {
            LASTKEY[i] = $KEYCOLS[i];
        }
        startrun(LASTKEY);
        reduce(LASTKEY);
    } else if (keymatches()) {
        reduce(LASTKEY);
    } else {
        endrun(LASTKEY);
        for(i in KEYCOLS) {
            LASTKEY[i] = $KEYCOLS[i];
        }
        startrun(LASTKEY);
        reduce(LASTKEY);
    }
}

END {
    if(NR > 0) {
        endrun(LASTKEY);
    }
}
