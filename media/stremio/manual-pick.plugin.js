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

  function progressText(record) {
    if (/^import/.test(record.trackedDownloadState || "")) return "Importando";
    if (!record.size) return "Baixando";
    return `Baixando ${Math.floor((1 - record.sizeleft / record.size) * 100)}%`;
  }

  // A season pack is one torrent but one queue record per episode, all with the same downloadId.
  function queueByHash(records, app) {
    const byHash = new Map();
    for (const r of records) {
      if (!r.downloadId) continue;
      const hash = r.downloadId.toLowerCase();
      const entry = byHash.get(hash) || { app, ids: [], itemId: r.movieId ?? r.seriesId, text: progressText(r) };
      entry.ids.push(r.id);
      entry.cancelable = entry.text !== "Importando";
      byHash.set(hash, entry);
    }
    return byHash;
  }

  // The hash of the download whose file the item has now; the caller checks the item still has a file.
  function importedHash(history, key, id) {
    const imports = history.filter((h) => h[key] === id && h.eventType === "downloadFolderImported" && h.downloadId);
    if (!imports.length) return null;
    const latest = imports.reduce((a, b) => (Date.parse(b.date) > Date.parse(a.date) ? b : a));
    return latest.downloadId.toLowerCase();
  }

  function rowState(local, queued, inLibrary) {
    if (local?.busy) return { text: local.text, menu: local.text, icon: "download", action: "none" };
    if (local?.error) {
      const action = queued?.cancelable ? "cancel" : queued ? "none" : "pick";
      return { text: local.text, menu: local.text, icon: action === "cancel" ? "cancel" : "download", action };
    }
    if (queued?.cancelable) return { text: queued.text, menu: "Cancelar download", icon: "cancel", action: "cancel" };
    if (queued) return { text: queued.text, menu: queued.text, icon: "download", action: "none" };
    if (inLibrary) return { text: "No PC", menu: "Já está no PC", icon: "done", action: "none" };
    return { text: local?.text || "", menu: local?.text || "Baixar no PC", icon: "download", action: "pick" };
  }

  function emptyAfterCancel(app, item) {
    return app === "radarr" ? !item.hasFile : !item.statistics?.episodeFileCount;
  }

  const api = {
    parseRoute, streamRelease, torrentioStreams, isAnime, movieAddBody, seriesAddBody, isPack,
    episodesToMonitor, planClick, pickedItem, pushBody, pushError, progressText, queueByHash, importedHash,
    rowState, emptyAfterCancel,
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

  const ICONS = {
    download: "M12 3v12m0 0-5-5m5 5 5-5M5 20h14",
    cancel: "M6 6l12 12M18 6 6 18",
    done: "M5 12.5l4.5 4.5L19 7",
  };
  const local = new Map();
  let streams = new Map();
  let remote = { key: null, queue: new Map(), inLibrary: null };

  function routeKey(route) {
    return route && [route.type, route.imdb, route.season, route.episode].join(":");
  }

  async function libraryHash(route) {
    if (route.type === "movie") {
      const movie = (await call("radarr", "GET", "/movie")).find((m) => m.imdbId === route.imdb);
      if (!movie?.hasFile) return null;
      return importedHash(await call("radarr", "GET", `/history/movie?movieId=${movie.id}`), "movieId", movie.id);
    }
    const series = (await call("sonarr", "GET", "/series")).find((s) => s.imdbId === route.imdb);
    if (!series) return null;
    const ep = (await call("sonarr", "GET", `/episode?seriesId=${series.id}`))
      .find((e) => e.seasonNumber === route.season && e.episodeNumber === route.episode);
    if (!ep?.hasFile) return null;
    return importedHash(await call("sonarr", "GET", `/history/series?seriesId=${series.id}`), "episodeId", ep.id);
  }

  let refreshing = false;
  let lastRefreshError = "";
  async function refresh() {
    const route = parseRoute(location.hash);
    if (refreshing || !route) return;
    refreshing = true;
    try {
      const key = routeKey(route);
      const app = route.type === "movie" ? "radarr" : "sonarr";
      const queue = queueByHash((await call(app, "GET", "/queue?pageSize=1000")).records, app);
      const finished = [...remote.queue.keys()].some((h) => !queue.has(h));
      const inLibrary = key !== remote.key || finished ? await libraryHash(route) : remote.inLibrary;
      if (routeKey(parseRoute(location.hash)) === key) remote = { key, queue, inLibrary };
      for (const [href, s] of local) {
        if (!s.busy && !s.error && queue.has(streams.get(href)?.infoHash?.toLowerCase())) local.delete(href);
      }
      lastRefreshError = "";
    } catch (e) {
      const text = pushError(e);
      if (text !== lastRefreshError) SE.logger.warn(`queue: ${JSON.stringify(e)}`);
      lastRefreshError = text;
    } finally {
      refreshing = false;
    }
    render();
  }

  function stateOf(href) {
    const hash = streams.get(href)?.infoHash?.toLowerCase();
    return rowState(local.get(href), remote.queue.get(hash), hash != null && hash === remote.inLibrary);
  }

  async function pick(href, stream) {
    const route = parseRoute(location.hash);
    if (!route) return;
    local.set(href, { text: "Enviando…", busy: true });
    render();
    try {
      const release = streamRelease(stream);
      await (route.type === "movie" ? pickMovie(route, release) : pickEpisode(route, release));
      local.set(href, { text: "Baixando" });
    } catch (e) {
      local.set(href, { text: pushError(e), error: true });
      SE.logger.error(JSON.stringify(e));
    }
    await refresh();
  }

  async function cancel(href, stream) {
    const entry = remote.queue.get(stream.infoHash.toLowerCase());
    const title = streamRelease(stream).title;
    const choice = await SE.showAlert("warning", "Cancelar download",
      `Parar de baixar ${title}? O que já baixou é apagado.`, ["Cancelar download", "Voltar"]);
    if (choice !== 0 || !entry) return;
    local.set(href, { text: "Cancelando…", busy: true });
    render();
    try {
      await call(entry.app, "DELETE", "/queue/bulk?removeFromClient=true&blocklist=false", { ids: entry.ids });
      const others = (await call(entry.app, "GET", "/queue?pageSize=1000")).records
        .some((r) => (r.movieId ?? r.seriesId) === entry.itemId);
      const path = entry.app === "radarr" ? `/movie/${entry.itemId}` : `/series/${entry.itemId}`;
      if (!others && emptyAfterCancel(entry.app, await call(entry.app, "GET", path))) {
        await call(entry.app, "DELETE", `${path}?deleteFiles=false&addImportExclusion=false`);
      }
      local.delete(href);
    } catch (e) {
      local.set(href, { text: pushError(e), error: true });
      SE.logger.error(JSON.stringify(e));
    }
    await refresh();
  }

  // render runs from a MutationObserver, so writing an unchanged value would wake it again forever.
  function set(el, prop, value) {
    if (el[prop] !== value) el[prop] = value;
  }

  // React owns the original icon and label, so they are hidden and ours sit beside them.
  function ourIcon(svg, icon) {
    if (!svg) return;
    if (!svg.dataset.manualPick) {
      svg.dataset.manualPick = "original";
      const ours = document.createElementNS("http://www.w3.org/2000/svg", "svg");
      ours.setAttribute("class", svg.getAttribute("class") || "");
      ours.setAttribute("viewBox", "0 0 24 24");
      ours.dataset.manualPick = "1";
      svg.style.display = "none";
      svg.after(ours);
    }
    const ours = svg.nextElementSibling;
    if (ours?.dataset.icon === icon) return;
    ours.dataset.icon = icon;
    ours.innerHTML = `<path d="${ICONS[icon]}" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`;
  }

  function dress(a) {
    const state = stateOf(a.getAttribute("href"));
    const label = a.querySelector('[class*="menu-label-"]');
    if (label) {
      ourIcon(a.querySelector(':scope > svg[data-manual-pick="original"], :scope > svg:not([data-manual-pick])'), state.icon);
      let ours = a.querySelector(".manual-pick-label");
      if (!ours) {
        ours = label.cloneNode(false);
        ours.classList.add("manual-pick-label");
        label.style.display = "none";
        label.after(ours);
      }
      set(ours, "textContent", state.menu);
      set(a, "title", state.menu);
      return;
    }
    const play = a.querySelector('[class*="play-"]');
    if (!play) return;
    ourIcon(play.querySelector('svg[data-manual-pick="original"], svg:not([data-manual-pick])'), state.icon);
    let note = play.querySelector(".manual-pick-status");
    if (!note) {
      note = document.createElement("span");
      note.className = "manual-pick-status";
      note.style.cssText = "font-size:0.85rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis";
      play.prepend(note);
    }
    set(note, "textContent", state.text);
    set(note, "hidden", !state.text);
    set(a, "title", state.action === "cancel" ? `${state.text}: clique para cancelar` : state.text || "Baixar no PC");
    const pill = state.text
      ? "display:flex;flex-direction:row;align-items:center;width:auto;max-width:12rem;padding:0 0.8rem;gap:0.4rem;border-radius:999px"
      : "";
    if (play.dataset.manualPill !== pill) (play.dataset.manualPill = pill), (play.style.cssText = pill);
  }

  function render() {
    for (const a of document.querySelectorAll('a[href^="#/player/"]')) {
      if (!streams.has(a.getAttribute("href"))) continue;
      if (!a.dataset.manualPick) a.dataset.manualPick = "1";
      dress(a);
    }
  }

  window.addEventListener(
    "click",
    (ev) => {
      const a = ev.target.closest?.("a[data-manual-pick]");
      const href = a?.getAttribute("href");
      const s = href && streams.get(href);
      if (!s) return;
      ev.preventDefault();
      ev.stopPropagation();
      const { action } = stateOf(href);
      if (action === "pick") pick(href, s);
      else if (action === "cancel") cancel(href, s);
    },
    true,
  );

  let pending = false;
  async function decorate() {
    pending = false;
    const route = parseRoute(location.hash);
    if (!route || !document.querySelector('a[href^="#/player/"]')) return;
    streams = torrentioStreams(await globalThis.core.getState("meta_details"));
    if (routeKey(route) !== remote.key) refresh();
    render();
  }

  new MutationObserver(() => {
    if (!pending) (pending = true), setTimeout(decorate, 300);
  }).observe(document.documentElement, { childList: true, subtree: true });

  setInterval(() => {
    if (document.visibilityState === "visible" && document.querySelector('a[data-manual-pick="1"]')) refresh();
  }, 5000);
})();
