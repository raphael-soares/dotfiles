import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const P = require("../media/stremio/manual-pick.plugin.js");

const cfg = { profileId: 9, animeTagId: 2 };

test("parseRoute reads a series episode", () => {
  assert.deepEqual(P.parseRoute("#/detail/series/tt0944947/tt0944947%3A2%3A3"),
    { type: "series", imdb: "tt0944947", season: 2, episode: 3 });
  assert.deepEqual(P.parseRoute("#/detail/movie/tt1254207/tt1254207"), { type: "movie", imdb: "tt1254207" });
  assert.equal(P.parseRoute("#/discover"), null);
  assert.equal(P.parseRoute("#/detail/series/tt0944947"), null);
});

test("streamRelease builds the magnet from a stream in Stremio's state", () => {
  const r = P.streamRelease({ infoHash: "ABC", description: "Dune.2024.1080p.BluRay\n👤 120 💾 9.8 GB", announce: ["tracker:udp://t:1", "dht:ABC"] });
  assert.equal(r.infoHash, "abc");
  assert.equal(r.title, "Dune.2024.1080p.BluRay");
  assert.match(r.magnet, /^magnet:\?xt=urn:btih:abc&/);
  assert.match(r.magnet, /tr=udp%3A%2F%2Ft%3A1/);
  assert.doesNotMatch(r.magnet, /dht/);
});

test("torrentioStreams keeps only Torrentio's ready streams", () => {
  const s = { infoHash: "a", description: "x", deepLinks: { player: "#/player/1" } };
  const state = { streams: [
    { addon: { manifest: { id: "com.stremio.torrentio.addon" } }, content: { type: "Ready", content: [s] } },
    { addon: { manifest: { id: "other" } }, content: { type: "Ready", content: [{ ...s, deepLinks: { player: "#/player/2" } }] } },
    { addon: { manifest: { id: "com.stremio.torrentio.addon" } }, content: { type: "Err" } },
  ] };
  assert.deepEqual([...P.torrentioStreams(state).keys()], ["#/player/1"]);
  assert.equal(P.torrentioStreams({}).size, 0);
});

test("isAnime follows the Anime genre", () => {
  assert.equal(P.isAnime({ genres: ["Animation", "Anime"] }), true);
  assert.equal(P.isAnime({ genres: ["Animation"] }), false);
  assert.equal(P.isAnime({}), false);
});

test("movieAddBody adds without searching", () => {
  const b = P.movieAddBody({ title: "Dune", tmdbId: 1 }, cfg);
  assert.equal(b.qualityProfileId, 9);
  assert.equal(b.rootFolderPath, "/home/raphael/Media/Movies");
  assert.equal(b.minimumAvailability, "released");
  assert.equal(b.monitored, true);
  assert.equal(b.addOptions.searchForMovie, false);
});

test("seriesAddBody sends anime to the anime folder, untouched by search", () => {
  const b = P.seriesAddBody({ title: "JoJo", tvdbId: 9, genres: ["Anime"], seasons: [{ seasonNumber: 1, monitored: true }] }, cfg);
  assert.equal(b.rootFolderPath, "/home/raphael/Media/Anime");
  assert.equal(b.seriesType, "anime");
  assert.equal(b.qualityProfileId, 9);
  assert.deepEqual(b.tags, [2]);
  assert.equal(b.seasonFolder, true);
  assert.equal(b.monitored, true);
  assert.equal(b.addOptions.monitor, "skip");
  assert.deepEqual(b.seasons, [{ seasonNumber: 1, monitored: false }]);
  assert.equal(b.addOptions.searchForMissingEpisodes, false);
  const s = P.seriesAddBody({ title: "Dark", tvdbId: 8, genres: ["Drama"] }, cfg);
  assert.equal(s.rootFolderPath, "/home/raphael/Media/Series");
  assert.equal(s.seriesType, "standard");
  assert.deepEqual(s.tags, []);
});

test("isPack tells a season pack from an episode", () => {
  assert.equal(P.isPack("Show.S01.1080p.WEB"), true);
  assert.equal(P.isPack("Show Season 2 Complete"), true);
  assert.equal(P.isPack("Show Temporada 3 1080p"), true);
  assert.equal(P.isPack("Show.S01E02.1080p"), false);
  assert.equal(P.isPack("Show.S01E01-E03.1080p"), false);
});

test("episodesToMonitor takes the whole season for a pack", () => {
  const eps = [
    { id: 1, seasonNumber: 1, episodeNumber: 1 },
    { id: 2, seasonNumber: 1, episodeNumber: 2 },
    { id: 3, seasonNumber: 2, episodeNumber: 1 },
  ];
  assert.deepEqual(P.episodesToMonitor(eps, 1, 2, true), [1, 2]);
  assert.deepEqual(P.episodesToMonitor(eps, 1, 2, false), [2]);
});

test("planClick adds only what Radarr or Sonarr lacks", () => {
  assert.deepEqual(P.planClick(42), ["monitor", "push"]);
  assert.deepEqual(P.planClick(null), ["add", "monitor", "push"]);
});

test("pickedItem moves an existing title to the Manual profile and monitors it", () => {
  const m = P.pickedItem({ id: 4, qualityProfileId: 7, monitored: false, title: "Dune" }, 9);
  assert.equal(m.qualityProfileId, 9);
  assert.equal(m.monitored, true);
  assert.equal(m.title, "Dune");
});

test("pushBody hands the magnet over as a torrent", () => {
  const b = P.pushBody({ infoHash: "abc", title: "Dune.2024.1080p", magnet: "magnet:?xt=urn:btih:abc" }, "2026-11-24T00:00:00Z");
  assert.equal(b.protocol, "torrent");
  assert.equal(b.magnetUrl, "magnet:?xt=urn:btih:abc");
  assert.equal(b.title, "Dune.2024.1080p");
  assert.equal(b.publishDate, "2026-11-24T00:00:00Z");
});

test("pushError gives the owner something readable", () => {
  assert.equal(P.pushError(new TypeError("Failed to fetch")), "servidor fora de alcance");
  assert.equal(P.pushError(Object.assign(new Error("t"), { name: "TimeoutError" })), "servidor fora de alcance");
  assert.equal(P.pushError([{ rejections: ["Unknown Movie"] }]), "Unknown Movie");
  assert.equal(P.pushError({ message: "Series not found" }), "Series not found");
  assert.equal(P.pushError([{ rejections: ["Unable to parse"] }]), "nome sem título e ano reconhecíveis");
});
