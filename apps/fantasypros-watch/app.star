CBS_URL = "https://lasvegasffl.football.cbssports.com/scoring/live"

ABBR = {
    "The Rooster": "ROOSTER",
    "Stinkcave Bandit": "BANDIT",
    "Beefdrapes": "BEEF",
    "OldSchool101": "OS101",
    "DIMASSTYLE": "DIMA",
    "La Onda": "ONDA",
    "Latino Heat": "HEAT",
    "BIG WILL BIG THRILL": "BWBT",
    "All DAY & 2x on Sunday": "AD2XS",
    "Big Bowl of Gumbo": "BBOG",
    "Motor Boats and Mo's": "MBSB",
    "SOONER HIGH": "HIGH",
}


def fetch_live():
    r = http.get(
        CBS_URL,
        ttl_seconds=60,
        headers={
            "User-Agent": "Mozilla/5.0",
        },
    )

    if r["status_code"] != 200:
        return None

    return r["body"]


def parse_teams(body):
    teams = []
    parts = body.split('"starterSnsTotal":')

    for i in range(1, len(parts)):
        head = parts[i][:1200]

        if '"rosterPlayers":' not in head:
            continue

        name_marker = '"name": "'
        np = head.find(name_marker)

        if np < 0:
            continue

        name_rest = head[np + len(name_marker):]
        ne = name_rest.find('"')

        if ne < 0:
            continue

        name = name_rest[:ne]

        comma = head.find(",")

        if comma < 0:
            continue

        score = head[:comma].strip()

        if score == "null" or score == "":
            score = "0"

        prev = parts[i - 1]
        tail = prev[-1000:]

        matchup_marker = '"matchupId": ["'
        mp = tail.rfind(matchup_marker)

        if mp < 0:
            continue

        matchup_rest = tail[mp + len(matchup_marker):]
        me = matchup_rest.find('"')

        if me < 0:
            continue

        matchup_id = matchup_rest[:me]

        if name in ABBR:
            teams.append((matchup_id, name, score))

    return teams


def matchups(body):
    grouped = {}

    for matchup_id, name, score in parse_teams(body):
        if matchup_id not in grouped:
            grouped[matchup_id] = []

        grouped[matchup_id].append((name, score))

    out = []

    for mid in ["1", "2", "3", "4", "5", "6"]:
        if mid in grouped and len(grouped[mid]) >= 2:
            out.append(grouped[mid][:2])
        else:
            out.append([])

    return out


def draw(c, ctx, slot):
    c.fill("black")

    body = fetch_live()

    if body == None:
        c.text_center(
            "CBS FETCH ERROR",
            11,
            font="5x7",
            color="red",
        )
        return

    games = matchups(body)
    game = games[slot]

    if len(game) < 2:
        c.text_center(
            "CBS DATA ERROR",
            11,
            font="5x7",
            color="red",
        )
        return

    t1, s1 = game[0]
    t2, s2 = game[1]

    c.text_center(
        ABBR[t1] + " " + s1,
        2,
        font="6x8",
        color="green",
    )

    c.text_center(
        "VS " + ABBR[t2] + " " + s2,
        13,
        font="5x7",
        color="white",
    )

    c.text_center(
        "CBS LIVE " + str(slot + 1) + "/6",
        23,
        font="4x5",
        color="yellow",
    )


def p1(c, ctx):
    draw(c, ctx, 0)


def p2(c, ctx):
    draw(c, ctx, 1)


def p3(c, ctx):
    draw(c, ctx, 2)


def p4(c, ctx):
    draw(c, ctx, 3)


def p5(c, ctx):
    draw(c, ctx, 4)


def p6(c, ctx):
    draw(c, ctx, 5)
