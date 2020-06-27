(select(.stat == "code_birthdate_summary").data | map( {(.group) : .data }) | add |
{
    "most recent code": ((now - .ALL.max)/3600/24),
    "timespan": ((.ALL.max - .ALL.min)/3600/24),
    "LOC": .ALL.N,
    "died LOC": .died.N,
    "live LOC": .live.N
}),
(select(.stat == "code_lifetime_summary").data | map( {(.group) : .data }) | add |
{
    "died lifetime mean": (.died.mean / 3600/24),
    "died lifetime p05": (.died.p05 / 3600/24),
    "died lifetime p25": (.died.p25 / 3600/24),
    "died lifetime p50": (.died.p50 / 3600/24)
}),
(select(.stat == "code_lifetime_died_cdf").data |
{
    "7 day count": (.[] | select(.[0] == 3600*24*7) | .[1]),
    "14 day count": (.[] | select(.[0] == 3600*24*14) | .[1]),
    "30 day count": (.[] | select(.[0] == 3600*24*30) | .[1]),
    "60 day count": (.[] | select(.[0] == 3600*24*60) | .[1])
})
