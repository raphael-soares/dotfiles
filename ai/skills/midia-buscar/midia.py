#!/usr/bin/env python3
import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ENV = dict(
    line.split("=", 1)
    for line in (Path.home() / ".config/media/media.env").read_text().splitlines()
    if "=" in line and not line.startswith("#")
)
SEERR_KEY = json.loads((Path.home() / ".local/share/media/seerr/settings.json").read_text())["main"]["apiKey"]
CACHE = Path("/tmp/agents/midia-releases.json")
STATUS = {1: "unknown", 2: "pending", 3: "downloading", 4: "partial", 5: "available", 6: "deleted"}

APPS = {
    "seerr": ("http://127.0.0.1:5055/api/v1", {"X-Api-Key": SEERR_KEY}),
    "radarr": ("http://127.0.0.1:7878/api/v3", {"X-Api-Key": ENV["RADARR__AUTH__APIKEY"]}),
    "sonarr": ("http://127.0.0.1:8989/api/v3", {"X-Api-Key": ENV["SONARR__AUTH__APIKEY"]}),
    "jellyfin": ("http://127.0.0.1:8096", {"Authorization": f'MediaBrowser Token="{ENV["JELLYFIN_TOKEN"]}"'}),
}


def call(app, path, body=None, method=None, timeout=120):
    base, headers = APPS[app]
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method or ("POST" if data else "GET"),
                                 headers={**headers, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
    except urllib.error.HTTPError as e:
        sys.exit(f"{app} {e.code}: {e.read().decode()[:300]}")
    return json.loads(raw) if raw else None


def q(s):
    return urllib.parse.quote(s)


def cmd_search(a):
    for r in call("seerr", f"/search?query={q(a.term)}&page=1")["results"]:
        if r["mediaType"] not in ("movie", "tv"):
            continue
        title = r.get("title") or r.get("name")
        year = (r.get("releaseDate") or r.get("firstAirDate") or "")[:4]
        status = STATUS.get((r.get("mediaInfo") or {}).get("status"), "not requested")
        print(f'{r["mediaType"]:5} tmdb={r["id"]:<8} {year:4} {title}  [{status}]')


def cmd_request(a):
    body = {"mediaType": a.type, "mediaId": a.tmdb}
    if a.type == "tv":
        body["seasons"] = "all" if a.seasons == "all" else [int(s) for s in a.seasons.split(",")]
    r = call("seerr", "/request", body)
    print(f'request {r["id"]} status={r["status"]} (2 = approved, sent to Radarr/Sonarr)')


def find_series(term):
    hits = [s for s in call("sonarr", "/series") if term.lower() in s["title"].lower()]
    if not hits:
        sys.exit(f"no series matching {term!r} in Sonarr; search and request it first")
    return hits[0]


def find_movie(term):
    hits = [m for m in call("radarr", "/movie") if term.lower() in m["title"].lower()]
    if not hits:
        sys.exit(f"no movie matching {term!r} in Radarr; search and request it first")
    return hits[0]


def cmd_releases(a):
    if a.season is not None:
        s = find_series(a.term)
        eps = call("sonarr", f'/episode?seriesId={s["id"]}&seasonNumber={a.season}')
        ep = next((e for e in eps if e["episodeNumber"] == a.episode), None)
        if ep is None:
            sys.exit(f"S{a.season:02}E{a.episode:02} not found for {s['title']}")
        app, rels = "sonarr", call("sonarr", f'/release?episodeId={ep["id"]}', timeout=300)
        tag = re.compile(rf"S{a.season:02}E{a.episode:02}\b|(?<!\d){a.episode:02}(?!\d)", re.I)
        rels = [r for r in rels if tag.search(r["title"])]
    else:
        m = find_movie(a.term)
        app, rels = "radarr", call("radarr", f'/release?movieId={m["id"]}', timeout=300)
    if a.grep:
        rels = [r for r in rels if re.search(a.grep, r["title"])]
    rels.sort(key=lambda r: -r.get("seeders", 0))
    rels = rels[: a.limit]
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps({"app": app, "items": [{"guid": r["guid"], "indexerId": r["indexerId"]} for r in rels]}))
    for i, r in enumerate(rels):
        flag = "rejected" if r.get("rejected") else "ok"
        print(f'{i:2} seeds={r.get("seeders", 0):<5} {r["size"] // 2**20:>6}MB score={r.get("customFormatScore", 0):<5} {flag:8} {r["title"][:110]}')
        if r.get("rejected") and a.why:
            print("     " + "; ".join(r.get("rejections", [])))


def cmd_grab(a):
    c = json.loads(CACHE.read_text())
    item = c["items"][a.n]
    call(c["app"], "/release", item)
    print(f"grabbed #{a.n} via {c['app']}; it lands in Jellyfin after the download and import")


def cmd_queue(_):
    for app in ("radarr", "sonarr"):
        for r in call(app, "/queue?pageSize=100&includeUnknownSeriesItems=true")["records"]:
            left = 100 * (1 - r["sizeleft"] / r["size"]) if r.get("size") else 0
            msgs = "; ".join(m for s in r.get("statusMessages", []) for m in s.get("messages", []))
            print(f'{app:6} {left:5.1f}% {r["trackedDownloadState"]:16} {r["title"][:80]} {msgs[:120]}')


def cmd_audio(a):
    items = call("jellyfin", f"/Items?searchTerm={q(a.term)}&Recursive=true&IncludeItemTypes=Movie,Episode&Fields=MediaStreams&Limit=50")
    for it in items["Items"]:
        langs = sorted({s.get("Language") or "und" for s in it.get("MediaStreams", []) if s["Type"] == "Audio"})
        ep = f'S{it.get("ParentIndexNumber", 0):02}E{it.get("IndexNumber", 0):02} ' if it["Type"] == "Episode" else ""
        print(f'{it.get("SeriesName", "")} {ep}{it["Name"]}: audio {",".join(langs)}')


def cmd_import(a):
    s = find_series(a.term)
    files = call("sonarr", f"/manualimport?folder={q(a.folder)}&seriesId={s['id']}&filterExistingFiles=false")
    picked = [f for f in files if f.get("episodes") and (not a.grep or re.search(a.grep, f["path"]))]
    if not picked:
        sys.exit("no file there matched an episode; check the folder and --grep")
    body = [{"path": f["path"], "seriesId": s["id"], "episodeIds": [e["id"] for e in f["episodes"]],
             "quality": f["quality"], "languages": f["languages"], "releaseGroup": f.get("releaseGroup"),
             "downloadId": f.get("downloadId")} for f in picked]
    call("sonarr", "/command", {"name": "ManualImport", "files": body, "importMode": "auto"})
    for f in picked:
        print("importing", f["relativePath"])


p = argparse.ArgumentParser(prog="midia")
sub = p.add_subparsers(dest="cmd", required=True)
s = sub.add_parser("search"); s.add_argument("term"); s.set_defaults(f=cmd_search)
s = sub.add_parser("request"); s.add_argument("type", choices=["movie", "tv"]); s.add_argument("tmdb", type=int)
s.add_argument("--seasons", default="all"); s.set_defaults(f=cmd_request)
s = sub.add_parser("releases"); s.add_argument("term"); s.add_argument("--season", type=int); s.add_argument("--episode", type=int)
s.add_argument("--grep"); s.add_argument("--limit", type=int, default=20); s.add_argument("--why", action="store_true")
s.set_defaults(f=cmd_releases)
s = sub.add_parser("grab"); s.add_argument("n", type=int); s.set_defaults(f=cmd_grab)
s = sub.add_parser("queue"); s.set_defaults(f=cmd_queue)
s = sub.add_parser("audio"); s.add_argument("term"); s.set_defaults(f=cmd_audio)
s = sub.add_parser("import"); s.add_argument("term"); s.add_argument("folder"); s.add_argument("--grep")
s.set_defaults(f=cmd_import)
a = p.parse_args()
if a.cmd == "releases" and (a.season is None) != (a.episode is None):
    p.error("--season and --episode go together")
a.f(a)
