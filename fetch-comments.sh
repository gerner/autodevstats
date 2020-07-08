#!/bin/bash

#TODO: these should really be passed as options
if [ -z "$SILENT" ]; then
    SILENT="false"
fi

if [ -z "${PREFIX_URL}" ]; then
    PREFIX_URL="false"
fi

if [ -z "${MAX_PAGES}" ]; then
    MAX_PAGES=""
fi

if [ -z "${HEADER_ACCEPT}" ]; then
    HEADER_ACCEPT=""
fi

set -eu -o pipefail

#make sure we can recover some info if we die in the middle of fetching data
trap 'echo "[ERROR] Error occurred at $BASH_SOURCE:$LINENO command: $BASH_COMMAND exit: $?" > /dev/stderr' ERR

#assume env var "GITHUB_TOKEN" set

# output to standard out, uncomment lines below (plus more echo to stdout below)
#  to output a to file
# let user pass some stuff in
#if [ -z "$ALLCOMMENTS" ]; then
#    ALLCOMMENTS=$(mktemp --tmpdir allcomments.XXXXXXXXXX)
#fi
#echo "writing comments to ${ALLCOMMENTS}" > /dev/stderr

#if [ -z "$1" ]; then
#    OWNER="rails"
#    REPO="rails"
#    NEXTURL="https://api.github.com/repos/${OWNER}/${REPO}/pulls/comments?since=1970-01-01T00:00:00Z&per_page=100"
#else
#    NEXTURL="$1"
#fi

RETRY_TIME=1
RETRY_MAX_COUNT=8

#a fifo for tracking progress for each input url
PV_PIDFILE=$(mktemp -u --tmpdir autodev_fetch_pvpid.XXXXXXXXXX)
FETCH_FIFO=$(mktemp -u --tmpdir autodev_fetch_fifo.XXXXXXXXXX)
$SILENT || mkfifo $FETCH_FIFO

while read NEXTURL; do

    $SILENT || echo "fetching ${NEXTURL}" > /dev/stderr

    #HEADERS=/tmp/headers.last
    HEADERS=$(mktemp --tmpdir headers.XXXXXXXXXX)
    #COMMENTS=/tmp/comments.last
    COMMENTS=$(mktemp --tmpdir comments.XXXXXXXXXX)

    TOTALPAGES=""

    #set up a progress meter for this input url
    $SILENT || pv -P $PV_PIDFILE -l $FETCH_FIFO > /dev/null &
    $SILENT || exec 3>$FETCH_FIFO

    pages=0
    retry_count=0
    retry_sleep=$RETRY_TIME
    while [ ! -z "${NEXTURL}" ]; do
        if [ ! -z "${MAX_PAGES}" ]; then
            if [[ "${pages}" -ge "${MAX_PAGES}" ]]; then
                break;
            fi
        fi


        if (! curl -L --compressed -s -D ${HEADERS} -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: ${HEADER_ACCEPT}" "${NEXTURL}" > ${COMMENTS} ) || grep -E --silent '^HTTP/[^ ]+ +5[0-9][0-9]' ${HEADERS}; then
            #handle server errors with retry
            #we do this manually to avoid polluting the output with server
            #error output
            if [ "$retry_count" -ge "$RETRY_MAX_COUNT" ]; then
                echo "exceeded max retry count ${retry_count} on ${NEXT_URL}" > /dev/stderr
                exit 1;
            fi
            retry_count=$(( $retry_count + 1 ))
            retry_sleep=$(( $retry_sleep * 2 ))
            sleep ${retry_sleep}
        elif grep --silent '403 Forbidden' ${HEADERS}; then
            retry_count=0
            retry_sleep=$RETRY_TIME
            #handle rate limiting
            echo "rate limit" > /dev/stderr

            reset_time=$(grep '^X-RateLimit-Reset: [0-9]*' ${HEADERS} | sed 's/^X-RateLimit-Reset: \([0-9]*\).*/\1/')

            grep 'X-RateLimit-' ${HEADERS} > /dev/stderr

            sleeptime=$(( ${reset_time} - $(date +%s) + 10 ))
            echo "sleeping $sleeptime" > /dev/stderr
            sleep ${sleeptime}
        #TODO: I don't think we should support 404 at all. no results should just be an empty array, not a 404
        #check if there simply are no results
        #elif grep --silent '404 Not Found' ${HEADERS}; then
        #    echo "no results for ${NEXTURL}" > /dev/stderr
        #    if [ -z "${TOTALPAGES}" ]; then
        #        exit
        #    else
        #        echo "this is unexpected as we should have ${TOTALPAGES} pages" > /dev/stderr
        #        exit 1
        #    fi
        else
            retry_count=0
            retry_sleep=$RETRY_TIME
            #check if there was some other error
            if ! grep --silent '200 OK' ${HEADERS}; then
                echo "got bad exit code, see ${HEADERS} for details" > /dev/stderr
                exit 1
            fi

            #optionally prefix with the url we just fetched
            ! ${PREFIX_URL} || printf "%s\t" ${NEXTURL}
            cat ${COMMENTS} | tr -d '\n' #>> ${ALLCOMMENTS}
            echo "" #>> ${ALLCOMMENTS}


            NEXTURL=$(cat ${HEADERS} | grep '^Link: ' | tr ',' '\n' | grep 'rel="next"' | sed 's/.*<\([^>]*\).*/\1/' || true)

            if [ -z "${TOTALPAGES}" ]; then
                TOTALPAGES=$(cat ${HEADERS} | grep '^Link: ' | tr ',' '\n' | grep 'rel="last"' | sed 's/.*<\([^>]*\).*/\1/' | sed 's/.*page=\([0-9]*\).*/\1/' | sed 's/.*page=\([0-9]*\).*/\1/' || echo "1")

                EXPECTED_PAGES=${TOTALPAGES}
                if [ ! -z "${MAX_PAGES}" ]; then
                    EXPECTED_PAGES=$(( ${MAX_PAGES} > ${TOTALPAGES} ? ${TOTALPAGES} : ${MAX_PAGES} ))
                fi

                $SILENT || echo "${TOTALPAGES} pages" > /dev/stderr
                $SILENT || pv -R $(cat $PV_PIDFILE) -s ${EXPECTED_PAGES}
            fi

            $SILENT || echo '.' > ${FETCH_FIFO}
        fi
        pages=$(( $pages + 1 ))
    done

    #close/cleanup the progress meter
    $SILENT || exec 3>&-

    #clean up state for this url
    #these will be left in place if something went wrong
    rm $HEADERS
    rm $COMMENTS

    $SILENT || echo "done" > /dev/stderr
done

$SILENT || rm $FETCH_FIFO
