/**
 * @name Manual Pick
 * @description Baixar no PC: sends the Torrentio release you picked to Radarr or Sonarr on the media server.
 * @version 1.0.0
 * @author raphael
 * @updateUrl none
 */

(function () {
  const OUT_OF_REACH = "servidor fora de alcance";
  const TORRENTIO = "com.stremio.torrentio.addon";
  const MOVIES = "/home/raphael/Media/Movies";
  const SERIES = "/home/raphael/Media/Series";
  const ANIME = "/home/raphael/Media/Anime";

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
    const title = stream.description.split("\n")[0].trim();
    const trackers = (stream.announce || [])
      .filter((s) => !s.startsWith("dht:"))
      .map((s) => "&tr=" + encodeURIComponent(s.replace(/^tracker:/, "")));
    const magnet = `magnet:?xt=urn:btih:${infoHash}&dn=${encodeURIComponent(title)}${trackers.join("")}`;
    return { infoHash, title, magnet };
  }

  function torrentioStreams(metaDetails) {
    const byLink = new Map();
    for (const group of metaDetails.streams || []) {
      if (group.addon?.manifest?.id !== TORRENTIO || group.content?.type !== "Ready") continue;
      for (const s of group.content.content) if (s.infoHash && s.deepLinks?.player) byLink.set(s.deepLinks.player, s);
    }
    return byLink;
  }

  function isAnime(lookup) {
    return (lookup.genres || []).includes("Anime");
  }

  function movieAddBody(lookup, cfg) {
    return {
      ...lookup,
      qualityProfileId: cfg.profileId,
      rootFolderPath: MOVIES,
      minimumAvailability: "released",
      monitored: true,
      addOptions: { searchForMovie: false },
    };
  }

  function seriesAddBody(lookup, cfg) {
    const anime = isAnime(lookup);
    return {
      ...lookup,
      qualityProfileId: cfg.profileId,
      rootFolderPath: anime ? ANIME : SERIES,
      seriesType: anime ? "anime" : "standard",
      tags: anime ? [cfg.animeTagId] : [],
      seasonFolder: true,
      monitored: true,
      seasons: (lookup.seasons || []).map((s) => ({ ...s, monitored: false })),
      // "none" unmonitors the series after Sonarr's refresh, racing the PUT that monitors it; push then fails.
      addOptions: { monitor: "skip", searchForMissingEpisodes: false, searchForCutoffUnmetEpisodes: false },
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
    return [...(existingId == null ? ["add"] : []), "monitor", "push"];
  }

  // Sonarr rejects a push for an unmonitored series or movie.
  function pickedItem(item, profileId) {
    return { ...item, qualityProfileId: profileId, monitored: true };
  }

  function pushBody(release, now) {
    return { title: release.title, magnetUrl: release.magnet, protocol: "torrent", publishDate: now };
  }

  function pushError(e) {
    if (e instanceof TypeError || e?.name === "TimeoutError" || e?.name === "AbortError") return OUT_OF_REACH;
    const first = Array.isArray(e) ? e[0] : e;
    const text = first?.rejections?.[0] || first?.message || first?.errorMessage || String(e);
    return text === "Unable to parse" ? "nome sem título e ano reconhecíveis" : text;
  }

  const api = {
    parseRoute, streamRelease, torrentioStreams, isAnime, movieAddBody, seriesAddBody, isPack,
    episodesToMonitor, planClick, pickedItem, pushBody, pushError,
  };
  globalThis.ManualPick = api;
  if (typeof module !== "undefined") module.exports = api;

  const SE = globalThis.StremioEnhancedAPI;
  if (!SE || !globalThis.document) return;

  const PLUGIN = "manual-pick";
  const PORTS = { radarr: 7878, sonarr: 8989 };
  SE.registerSettings(PLUGIN, [
    { key: "server", type: "input", label: "Servidor de mídia", defaultValue: "http://fedora.local" },
    { key: "radarr_key", type: "input", label: "Chave da API do Radarr" },
    { key: "sonarr_key", type: "input", label: "Chave da API do Sonarr" },
  ]);

  async function call(app, method, path, body) {
    const server = ((await SE.getSetting(PLUGIN, "server")) || "http://fedora.local").replace(/\/+$/, "");
    const res = await fetch(`${server}:${PORTS[app]}/api/v3${path}`, {
      method,
      headers: { "X-Api-Key": (await SE.getSetting(PLUGIN, `${app}_key`)) || "", "Content-Type": "application/json" },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(8000),
    });
    const data = await res.json().catch(() => null);
    if (!res.ok) throw data || { message: `${app} respondeu ${res.status}` };
    return data;
  }

  async function manualProfile(app) {
    const p = (await call(app, "GET", "/qualityprofile")).find((x) => x.name === "Manual");
    if (!p) throw { message: `perfil Manual não existe no ${app}` };
    return p.id;
  }

  async function push(app, release) {
    const [decision] = await call(app, "POST", "/release/push", pushBody(release, new Date().toISOString()));
    if (decision && decision.approved === false) throw [decision];
  }

  async function pickMovie(route, release) {
    const profileId = await manualProfile("radarr");
    // The /movie/lookup/imdb route leaves id null even for a film already in Radarr.
    const [lookup] = await call("radarr", "GET", `/movie/lookup?term=imdb:${route.imdb}`);
    if (!lookup) throw { message: "Radarr não achou este filme" };
    if (planClick(lookup.id)[0] === "add") {
      await call("radarr", "POST", "/movie", movieAddBody(lookup, { profileId }));
    } else {
      const item = await call("radarr", "GET", `/movie/${lookup.id}`);
      await call("radarr", "PUT", `/movie/${item.id}`, pickedItem(item, profileId));
    }
    await push("radarr", release);
  }

  async function seriesEpisodes(id) {
    for (let i = 0; i < 10; i++) {
      const eps = await call("sonarr", "GET", `/episode?seriesId=${id}`);
      if (eps.length) return eps;
      await new Promise((r) => setTimeout(r, 1000));
    }
    throw { message: "Sonarr ainda não carregou os episódios, tente de novo" };
  }

  async function pickEpisode(route, release) {
    const profileId = await manualProfile("sonarr");
    const [lookup] = await call("sonarr", "GET", `/series/lookup?term=imdb:${route.imdb}`);
    if (!lookup) throw { message: "Sonarr não achou esta série" };
    let id = lookup.id;
    if (planClick(id)[0] === "add") {
      const tag = (await call("sonarr", "GET", "/tag")).find((t) => t.label === "anime");
      id = (await call("sonarr", "POST", "/series", seriesAddBody(lookup, { profileId, animeTagId: tag?.id }))).id;
    }
    const item = await call("sonarr", "GET", `/series/${id}`);
    await call("sonarr", "PUT", `/series/${id}`, pickedItem(item, profileId));
    const episodeIds = episodesToMonitor(await seriesEpisodes(id), route.season, route.episode, isPack(release.title));
    await call("sonarr", "PUT", "/episode/monitor", { episodeIds, monitored: true });
    await push("sonarr", release);
  }

  function button(stream) {
    const b = document.createElement("button");
    b.className = "manual-pick";
    b.textContent = "Baixar no PC";
    b.style.cssText = "margin-left:auto;padding:0.4rem 0.8rem;border:0;border-radius:0.5rem;background:var(--secondary-accent-color,#7b5bf5);color:#fff;font:inherit;cursor:pointer;white-space:nowrap";
    b.addEventListener("click", async (ev) => {
      ev.preventDefault();
      ev.stopPropagation();
      const route = parseRoute(location.hash);
      if (!route || b.disabled) return;
      b.disabled = true;
      b.textContent = "Enviando…";
      try {
        const release = streamRelease(stream);
        await (route.type === "movie" ? pickMovie(route, release) : pickEpisode(route, release));
        b.textContent = "Baixando";
      } catch (e) {
        b.textContent = pushError(e);
        b.disabled = false;
        SE.error?.(`[manual-pick] ${JSON.stringify(e)}`);
      }
    });
    return b;
  }

  let pending = false;
  async function decorate() {
    pending = false;
    if (!parseRoute(location.hash)) return;
    const rows = [...document.querySelectorAll('a[href^="#/player/"]:not([data-manual-pick])')];
    if (!rows.length) return;
    const streams = torrentioStreams(await globalThis.core.getState("meta_details"));
    for (const a of rows) {
      const s = streams.get(a.getAttribute("href"));
      if (!s) continue;
      a.dataset.manualPick = "1";
      a.appendChild(button(s));
    }
  }

  new MutationObserver(() => {
    if (!pending) (pending = true), setTimeout(decorate, 300);
  }).observe(document.documentElement, { childList: true, subtree: true });
})();
