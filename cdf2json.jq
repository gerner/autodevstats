split("\n") | map(split("\t")) | .[0:-1] |
map([( .[0] | tonumber),(.[1]|tonumber)]) |
{
    "stat": $stat_name,
    "data": .
}
