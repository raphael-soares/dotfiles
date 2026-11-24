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
    if (e instanceof TypeError) return OUT_OF_REACH;
    if (e?.name === "TimeoutError" || e?.name === "AbortError") return "o servidor demorou demais, tente de novo";
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

  // Stremio Enhanced wraps each plugin with its own StremioEnhancedAPI, already bound to the plugin's name.
  const SE = typeof StremioEnhancedAPI === "undefined" ? undefined : StremioEnhancedAPI;
  if (!SE || !globalThis.document) return;

  const PORTS = { radarr: 7878, sonarr: 8989 };
  SE.registerSettings([
    { key: "server", type: "input", label: "Servidor de mídia", defaultValue: "http://fedora.local" },
    { key: "radarr_key", type: "input", label: "Chave da API do Radarr", description: "RADARR__AUTH__APIKEY no media.env" },
    { key: "sonarr_key", type: "input", label: "Chave da API do Sonarr", description: "SONARR__AUTH__APIKEY no media.env" },
  ]);

  async function call(app, method, path, body) {
    const server = ((await SE.getSetting("server")) || "http://fedora.local").replace(/\/+$/, "");
    const res = await fetch(`${server}:${PORTS[app]}/api/v3${path}`, {
      method,
      headers: { "X-Api-Key": (await SE.getSetting(`${app}_key`)) || "", "Content-Type": "application/json" },
      body: body === undefined ? undefined : JSON.stringify(body),
      // Adding a title waits on Radarr's or Sonarr's metadata server, which is often slow.
      signal: AbortSignal.timeout(30000),
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
      if (isAnime(lookup) && !tag) throw { message: "tag anime não existe no Sonarr" };
      id = (await call("sonarr", "POST", "/series", seriesAddBody(lookup, { profileId, animeTagId: tag?.id }))).id;
    }
    const item = await call("sonarr", "GET", `/series/${id}`);
    await call("sonarr", "PUT", `/series/${id}`, pickedItem(item, profileId));
    const episodeIds = episodesToMonitor(await seriesEpisodes(id), route.season, route.episode, isPack(release.title));
    await call("sonarr", "PUT", "/episode/monitor", { episodeIds, monitored: true });
    await push("sonarr", release);
  }

  const ICON =
    '<path d="M12 3v12m0 0-5-5m5 5 5-5M5 20h14" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>';
  const status = new Map();

  async function pick(href, stream) {
    const route = parseRoute(location.hash);
    if (!route || status.get(href)?.busy) return;
    status.set(href, { text: "Enviando…", busy: true });
    render();
    try {
      const release = streamRelease(stream);
      await (route.type === "movie" ? pickMovie(route, release) : pickEpisode(route, release));
      status.set(href, { text: "Baixando" });
    } catch (e) {
      status.set(href, { text: pushError(e) });
      SE.logger.error(JSON.stringify(e));
    }
    render();
  }

  // React owns the original icon and label, so they are hidden and ours sit beside them.
  function swapIcon(svg) {
    if (!svg || svg.dataset.manualPick) return;
    svg.dataset.manualPick = "original";
    const ours = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    ours.setAttribute("class", svg.getAttribute("class") || "");
    ours.setAttribute("viewBox", "0 0 24 24");
    ours.dataset.manualPick = "1";
    ours.innerHTML = ICON;
    svg.style.display = "none";
    svg.after(ours);
  }

  function dress(a) {
    const label = a.querySelector('[class*="menu-label-"]');
    if (label) {
      swapIcon(a.querySelector(":scope > svg"));
      let ours = a.querySelector(".manual-pick-label");
      if (!ours) {
        ours = label.cloneNode(false);
        ours.classList.add("manual-pick-label");
        label.style.display = "none";
        label.after(ours);
      }
      ours.textContent = status.get(a.getAttribute("href"))?.text || "Baixar no PC";
      a.title = "Baixar no PC";
      return;
    }
    const play = a.querySelector('[class*="play-"]');
    if (!play) return;
    swapIcon(play.querySelector("svg"));
    let note = play.querySelector(".manual-pick-status");
    if (!note) {
      note = document.createElement("span");
      note.className = "manual-pick-status";
      note.style.cssText = "font-size:0.85rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis";
      play.prepend(note);
    }
    const s = status.get(a.getAttribute("href"));
    note.textContent = s?.text || "";
    note.title = s?.text || "";
    play.style.cssText = s
      ? "display:flex;flex-direction:row;align-items:center;width:auto;max-width:12rem;padding:0 0.8rem;gap:0.4rem;border-radius:999px"
      : "";
  }

  let streams = new Map();
  function render() {
    for (const a of document.querySelectorAll('a[href^="#/player/"]')) {
      if (streams.has(a.getAttribute("href"))) (a.dataset.manualPick = "1"), dress(a);
    }
  }

  window.addEventListener(
    "click",
    (ev) => {
      const a = ev.target.closest?.("a[data-manual-pick]");
      const s = a && streams.get(a.getAttribute("href"));
      if (!s) return;
      ev.preventDefault();
      ev.stopPropagation();
      pick(a.getAttribute("href"), s);
    },
    true,
  );

  let pending = false;
  async function decorate() {
    pending = false;
    if (!parseRoute(location.hash)) return;
    if (!document.querySelector('a[href^="#/player/"]')) return;
    streams = torrentioStreams(await globalThis.core.getState("meta_details"));
    render();
  }

  new MutationObserver(() => {
    if (!pending) (pending = true), setTimeout(decorate, 300);
  }).observe(document.documentElement, { childList: true, subtree: true });
})();
