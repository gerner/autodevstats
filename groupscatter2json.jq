split("\n") | map(split("\t")) | .[0:-1] |
group_by(.[0]) |
{
    "stat": $stat_name,
    "data": [
        .[] | {"group": .[0][0], "data": map([(.[1]|tonumber), (.[2]|tonumber)])}
    ]
}
