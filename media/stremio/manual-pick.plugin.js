/**
 * @name Manual Pick
 * @description Baixar no PC: sends the Torrentio release you picked to Radarr or Sonarr on the media server.
 * @version 1.0.0
 * @author raphael
 * @updateUrl none
 */

(function () {
  const OUT_OF_REACH = "servidor fora de alcance";

  function parseRoute(hash) {
    const m = /^#\/detail\/(movie|series)\/(tt\d+)\/([^/?]+)/.exec(hash);
    if (!m) return null;
    if (m[1] === "movie") return { type: "movie", imdb: m[2] };
    const [, season, episode] = decodeURIComponent(m[3]).split(":").map(Number);
    if (!Number.isInteger(season) || !Number.isInteger(episode)) return null;
    return { type: "series", imdb: m[2], season, episode };
  }

  function streamRelease(stream) {
    const infoHash = stream.infoHash.toLowerCase();
    const title = stream.title.split("\n")[0].trim();
    const trackers = (stream.sources || [])
      .filter((s) => s.startsWith("tracker:"))
      .map((s) => "&tr=" + encodeURIComponent(s.slice("tracker:".length)));
    const magnet = `magnet:?xt=urn:btih:${infoHash}&dn=${encodeURIComponent(title)}${trackers.join("")}`;
    return { infoHash, title, magnet };
  }

  function isAnime(lookup) {
    return (lookup.genres || []).includes("Anime");
  }

  function movieAddBody(lookup, cfg) {
    return {
      ...lookup,
      qualityProfileId: cfg.movie.profileId,
      rootFolderPath: cfg.movie.root,
      minimumAvailability: "released",
      monitored: true,
      addOptions: { searchForMovie: false },
    };
  }

  function seriesAddBody(lookup, cfg) {
    const anime = isAnime(lookup);
    const kind = anime ? cfg.anime : cfg.series;
    return {
      ...lookup,
      qualityProfileId: kind.profileId,
      rootFolderPath: kind.root,
      seriesType: anime ? "anime" : "standard",
      tags: anime ? [cfg.anime.tagId] : [],
      seasonFolder: true,
      monitored: true,
      addOptions: { monitor: "none", searchForMissingEpisodes: false, searchForCutoffUnmetEpisodes: false },
    };
  }

  function isPack(title) {
    if (/S\d{1,2}E\d{1,3}/i.test(title)) return false;
    return /\bS\d{1,2}\b|\bSeason\s*\d+|\bTemporada\s*\d+/i.test(title);
  }

  function episodesToMonitor(episodes, season, episode, pack) {
    return episodes
      .filter((e) => e.seasonNumber === season && (pack || e.episodeNumber === episode))
      .map((e) => e.id);
  }

  function planClick(existingId) {
    return [...(existingId == null ? ["add"] : []), "monitor", "search", "grab"];
  }

  function releaseSearchPath(type, ids) {
    if (type === "movie") return `/release?movieId=${ids.movieId}`;
    if (ids.pack) return `/release?seriesId=${ids.seriesId}&seasonNumber=${ids.season}`;
    return `/release?episodeId=${ids.episodeId}`;
  }

  function findRelease(releases, infoHash) {
    const r = releases.find((x) => (x.infoHash || "").toLowerCase() === infoHash);
    return r ? { guid: r.guid, indexerId: r.indexerId } : null;
  }

  function pushBody(release, now) {
    return { title: release.title, magnetUrl: release.magnet, protocol: "torrent", publishDate: now };
  }

  function pushError(e) {
    if (e instanceof TypeError || e?.name === "TimeoutError" || e?.name === "AbortError") return OUT_OF_REACH;
    const first = Array.isArray(e) ? e[0] : e;
    return first?.rejections?.[0] || first?.message || first?.errorMessage || String(e);
  }

  const api = {
    parseRoute, streamRelease, isAnime, movieAddBody, seriesAddBody, isPack,
    episodesToMonitor, planClick, releaseSearchPath, findRelease, pushBody, pushError,
  };
  globalThis.ManualPick = api;
  if (typeof module !== "undefined") module.exports = api;
})();
