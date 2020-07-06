function get_lineid(commit_id, line_number) {
    lineid = sprintf("%s\t%d", commit_id, line_number);
    #lineid = substr($0, 2);
    return lineid;
}

function write_add_line(lineid, line) {
    lid=lineid;
    sub("\t", "-", lid)
    printf("%s\t%s\t%s\t%s\t%s\n", lid, lastfile, commit, sprintf("%d,%d", hunkstart_new, hunklen_new), line) >> addfile;
}

function write_rem_line(lineid, line) {
    lid=lineid;
    sub("\t", "-", lid)
    printf("%s\t%s\t%s\t%s\t%s\n", lid, lastfile, commit, sprintf("%d,%d", hunkstart_new, hunklen_new), line) >> remfile;
}

function leave_hunk() {
    if(numhunks == 0) {
        #there wasn't a hunk to leave, must be the first hunk in a diff
        return;
    }

    #print "leave hunk", numhunks, "line", NR > "/dev/stderr"

    #check that we're not leaving the same hunk twice
    if(numhunks == lastlefthunk) {
        print "error: left hunk ", lastlefthunk, " twice on line ", NR > "/dev/stderr";
        error = 1;
        exit 1;
    }
    lastlefthunk = numhunks;

    #TODO: stuff for leaving a hunk
    #TODO: dump a consolidated hunk
}

function leave_diff() {
    if(numdiffs == 0) {
        #there wasn't a diff to leave, must be the first diff in a merge
        #print "no diffs to leave", numdiffs > "/dev/stderr"
        return;
    }
    #print "leave diff", numdiffs, "line", NR > "/dev/stderr"

    if(numdiffs == lastleftdiff) {
        print "error: left diff ", lastleftdiff, " twice on line ", NR > "/dev/stderr";
        error = 1;
        exit 1;
    }

    lastleftdiff = numdiffs;

    #copy the rest of the file over to new file
    for(x=oldptr; x<oldfilelen; x++) {
        newfilearr[newptr] = filearr[oldptr]
        newptr += 1;
        oldptr += 1;
    }

    #replace old file with new file
    delete filearr;
    for(x=0; x<newptr; x++) {
        filearr[x] = newfilearr[x];

        #handy helper to dump file state
        #print newfilearr[x] > sprintf("/tmp/filecontent.%s", mergecommit);
    }

    if(newptr != expected_newfilelen) {
        print "error: expected new file to be ", expected_newfilelen, " from ", oldfilelen, " got ", newptr, " on line ", NR > "/dev/stderr"
        error = 1;
        exit 1;
    }

    oldfilelen = newptr;
}

function leave_file() {
    for(x in filearr) {
        printf("live\t%s\t%s\t%s\t%s\t%s\n", lastfile, mergecommit, commit, x, filearr[x]);
    }
}

# set output field separator to tab
BEGIN {
    error = 0;
    OFS="\t";
    #toggle this to output the actual code lines
    writeline = 0;
    if(codefile == "") {
        codefile = "/tmp/codefile";
    }
    if(addfile == "") {
        addfile = "/tmp/addfile";
    }
    if(remfile == "") {
        remfile = "/tmp/remfile";
    }
    if(binariesfile == "") {
        binariesfile = "/tmp/binariesfile";
    }

    added_lines = 0;
}

# handle leaving prior diff
/^merging / && NR>1 {
    leave_hunk();
    leave_diff();
}

# handle leaving file
NR > 1 && /^merging / && $4 != lastfile {
    leave_file();
}

# handle new file
/^merging / && $4 != lastfile {
    delete filearr;
    lastfile = $4;
    oldfilelen = 0;
    skipfile = 0;
}

# handle entering new merge
/^merging / {
    #print "enter merge", "line", NR > "/dev/stderr"
    mergecommit = $2;
    commit = $3;
    numdiffs=0;
    lastleftdiff=-1;
}

# handle entering new diff
/^diff / {
    #don't need to leave hunk/diff on the first diff
    #this will have been taken care of when we entered the merge
    if(numdiffs > 0) {
        leave_hunk();
        leave_diff();
    }

    numdiffs+=1;
    #print "enter diff", numdiffs, "line", NR > "/dev/stderr"


    oldptr = 0;
    newptr = 0;
    delete newfilearr;
    expected_newfilelen = oldfilelen;

    numhunks=0;
    lastlefthunk=-1;

    #either this is for us
    #or this is some weird corner case and the diff is not for us
    #and we should ignore it

    #line is of the form:
    #diff --git a/PATH_GOES_HERE b/PATH_GOES_HERE
    #note, PATH_GOES_HERE is always the same on left and right

    n = match($0, /diff --git "?a\/(.*)"? "?b\/(.*)"?/, matcharr);

    if(n <= 0) {
        print "got malformed diff line on ", NR > "/dev/stderr";
        error = 1;
        exit 1;
    }

    if(matcharr[1] != matcharr[2]) {
        print "got diff with mismatched files line on ", NR > "/dev/stderr";
        error = 1;
        exit 1;
    }

    if(matcharr[1] != lastfile) {
        skipdiff = 1;
    } else if (lastfile ~ /railties\/doc\/guides/) { #also skip some junk files)
        skipdiff = 1;
    } else if (skipfile) { #if we're skipping this file, skip the diff
        skipdiff = 1;
    } else {
        skipdiff = 0;
    }
}

#handle cases where a file doesn't get a diff because git thinks it's binary
#in this case we'll bail on parsing the diff (there isn't one) and the file
#since our state will not be up to date if there is a binary file in the future
/^Binary files a\/.* and b\/.* differ$/ {
    #force this diff to be skipped retroactively
    skipdiff = 1;
    #mark this file to be skipped for all following diffs in the file
    skipfile = 1;

    #keep track of these binary files so we can filter out downstream if the
    #file at one point had a diff, but then stopped (since our record of 
    #life/death will be wrong)
    printf("%s\t%s\n", lastfile, commit) >> binariesfile;
}


#oldptr points to the next line in oldfile we might keep (or be instructed
#to remove, not copying over to new file)
#newptr points to the next line in newfile we are creating.
#lines will come from oldptr or from added lines from diff hunks
#old and new pointers are zero-indexed

# handle new diff hunk
# diff hunk header is of the form:
# @@ -OLD_LINE[,OLD_LEN] +NEW_LINE[,NEW_LEN] @@
# OLD_LINE and NEW_LINE refer to the line number being shown
# OLD_LEN and NEW_LEN refer to the number of lines being shown, default is 1,
# but might be zero if there are no lines from that diff to show
/^@@ / {
    if(skipdiff) {
        next;
    }

    #only leave_hunk if we're in the same diff
    leave_hunk()
    numhunks += 1;

    #print "enter hunk", numhunks, "line", NR > "/dev/stderr"

    #parse hunk header
    if(match($0, /^@@ -([0-9]+)(,([0-9]+))? \+([0-9]+)(,([0-9]+))? @@/, matcharr) != 1) {
        print "error parsing hunk header on line", NR > "/dev/stderr";
        error = 1;
        exit 1;
    }

    #pull out relevant values, handling default case
    oldline = int(matcharr[1]);
    oldlen = (matcharr[3] == "") ? 1 : int(matcharr[3]);
    newline = int(matcharr[4]);
    newlen = (matcharr[6] == "") ? 1 : int(matcharr[6]);

    #if oldlen == 0 (assume newlen != 0), we are adding content AFTER oldline
    #   so we need to copy up to, and including oldline
    #else, we are removing at least some content starting at oldline,
    #   so we need to copy up to, but excluding oldline
    #if newlen == 0 (assume oldlen != 0), we are strictly removing content,
    #   newline refers to the last line that appears in newfile
    #else, we are adding new content
    #   newline refers to the first line of that new content
    #   so we should be prepared to write our next line there

    #if both are non-zero, we are replacing one hunk with another
    #   so we need to copy up to, but excluding oldline

    #old and new lines are one-indexed

    #copy up to and possibly including oldline
    copyend = (oldlen == 0) ? (oldline) : oldline-1;
    for(;oldptr < copyend;) {
        newfilearr[newptr] = filearr[oldptr];
        newptr += 1;
        oldptr += 1;
    }

    hunkstart_new = newptr;
    hunklen_new = newlen;
    hunkstart_old = oldptr;
    hunklen_old = oldlen;

    #error checking on newptr
    if(newlen == 0 && newptr-1 != newline-1) {
        print sprintf("mismatch in newfile %d vs %d (len=%d copyend=%d) on %d", newptr, newline, newlen, copyend, NR) > "/dev/stderr"
        error = 1;
        exit 1;
    } else if(newlen != 0 && newptr != newline-1) {
        print sprintf("mismatch in newfile %d vs %d (len=%d copyend=%d) on %d", newptr, newline, newlen, copyend, NR) > "/dev/stderr"
        erorr = 1;
        exit 1;
    }
}

#skip pesky header lines
/^\+\+\+|^---/ && numhunks == 0 {
    next
}

#common lines
/^ / {
    if(skipdiff) {
        next;
    }

    newfilearr[newptr] = filearr[oldptr]

    if(writeline) {
        write_add_line(newfilearr[newptr], substr($0, 2));
        write_rem_line(filearr[oldptr], substr($0, 2));
    }

    newptr++;
    oldptr++;
}

#added lines
/^\+/ {
    if(skipdiff) {
        next;
    }

    lineid = get_lineid(commit, newptr);
    printf("born\t%s\t%s\t%s\t%s\t%s\n", lastfile, mergecommit, commit, newptr, lineid);

    if(writeline) {
        printf("%d\t%s\t%s\t%s\n", added_lines, lastfile, lineid, substr($0, 2)) >> codefile;
        added_lines += 1
    }

    newfilearr[newptr] = lineid;

    if(writeline) {
        write_add_line(lineid, substr($0, 2));
    }

    newptr +=1;
    expected_newfilelen += 1;
}

#removed lines
/^-/ {
    if(skipdiff) {
        next;
    }

    lineid = filearr[oldptr];
    if(lineid == "") {
        print("no lineid found on line", NR);
        error = 1;
        exit 1;
    }

    printf("died\t%s\t%s\t%s\t%s\t%s\n", lastfile, mergecommit, commit, oldptr, lineid);

    if(writeline) {
        write_rem_line(lineid, substr($0, 2));
    }

    oldptr +=1;
    expected_newfilelen -= 1;
}

END {
    if(lastfile != "" && !error) {
        leave_hunk();
        leave_diff();
        leave_file();
    }
}
