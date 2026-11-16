// Sessionizer: o mesmo do tmux (prefixo Tab). Spaces abertos primeiro (*), depois
// as pastas do `tmux-sessionizer.sh --dirs` sem space aberto. Digite para filtrar,
// ↑/↓ (ou ctrl-n/p, ctrl-j/k) e Enter para ir, ctrl-x fecha um space, Esc sai.
// Com props `ssh` (prefixo S) lista os hosts do `ssh-sessionizer.sh --hosts`:
// cada host é uma tab com o nome dele no space "ssh", reaproveitada se já existe.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, panes, run, exec, home, notify, theme, settings, props, closeOverlay, shared, setShared } from "herdr";

const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// Space colors, kept by space id in shared "space.colors": a theme
// color name ("ansi6") or a picked #rrggbb. A space seen without one gets
// the theme color fewest spaces use, once; every mod does the same in the
// same order, so they agree, and adding or renaming spaces moves nothing.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : (MARK[c] ?? t[c]);
}

// Where a space is now: its first terminal's live folder, else where it was made.
function place(s, all = panes()) {
  if (!s) return null;
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return all.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder || null;
}

// Each character of the query appears in order in the text, like fzf.
function matches(query, text) {
  let i = 0;
  const t = text.toLowerCase();
  for (const ch of query.toLowerCase()) {
    i = t.indexOf(ch, i);
    if (i < 0) return false;
    i++;
  }
  return true;
}

const spaceLabel = (s) => `* ${s.name}${s.machine ? `  (${s.machine})` : ""}`;

export default class Sessionizer extends View {
  init(_props, cx) {
    this.ssh = Boolean(props()?.ssh);
    this.filter = "";
    this.at = 0;
    this.scroll = 0;
    this.dirs = [];
    this.hosts = [];
    this.input = InputState.new({ placeholder: this.ssh ? "Host…" : "Space ou pasta…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", () => this.go(this.rows()[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      const aviso = this.ssh ? "SSH sem hosts" : "Sessionizer sem pastas";
      try {
        const r = this.ssh
          ? await exec(`${home()}/.config/tmux/ssh-sessionizer.sh`, ["--hosts"])
          : await exec(`${home()}/.config/tmux/tmux-sessionizer.sh`, ["--dirs"]);
        if (r.code !== 0) {
          notify({ title: aviso, body: r.stderr.trim().split("\n")[0] || `saiu com ${r.code}`, level: "warning" });
        } else if (this.ssh) {
          this.hosts = r.stdout.trim().split("\n").filter(Boolean);
        } else {
          this.dirs = r.stdout.trim().split("\n").filter(Boolean).map((l) => {
            const [label, path] = l.split("\t");
            return { label, path };
          });
        }
      } catch (e) {
        notify({ title: aviso, body: String(e?.message ?? e), level: "warning" });
      }
      cx.notify();
    });
  }

  close() {
    closeOverlay(props().overlay);
  }

  sshSpace() {
    return spaces().find((s) => s.named && s.name === "ssh" && s.machine === null);
  }

  rows() {
    const f = this.filter;
    let out;
    if (this.ssh) {
      const tabs = this.sshSpace()?.tabs ?? [];
      out = this.hosts.map((h) => ({ kind: "host", label: h, tab: tabs.find((c) => c.named && c.name === h) }));
    } else {
      const all = spaces();
      const live = panes();
      const open = all.filter((s) => s.machine === null).map((s) => place(s, live)).filter(Boolean);
      out = all.map((s) => ({ kind: "space", s, label: spaceLabel(s) }));
      for (const d of this.dirs) {
        if (!open.some((p) => p === d.path || p.startsWith(d.path + "/"))) out.push({ kind: "dir", ...d });
      }
    }
    return f ? out.filter((r) => matches(f, r.label)) : out;
  }

  go(r) {
    if (!r) return;
    this.close();
    if (r.kind === "space") run("space.select", { id: r.s.id });
    else if (r.kind === "dir") run("space.new", { folder: r.path, machine: "" });
    else this.abrirHost(r);
  }

  abrirHost(r) {
    const s = this.sshSpace();
    const argv = ["ssh", r.label];
    if (!s) return run("space.new", { name: "ssh", tab: r.label, folder: home(), machine: "", argv });
    run("space.select", { id: s.id });
    if (r.tab) run("tab.select", { id: r.tab.id });
    else run("tab.new", { name: r.label, space: s.id, folder: home(), argv });
  }

  render() {
    const t = theme();
    const rows = this.rows();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const sel = rows[this.at];
    // One continuous strip: each row at a fixed y. Scrolling moves the strip only
    // as far as it takes to keep the selected row in view.
    const H = 32;
    const total = rows.length * H;
    const height = Math.min(320, this.listHeight ?? 320);
    const fixed = total > height;
    const maxScroll = Math.max(0, total - height);
    this.scroll = Math.max(0, Math.min(this.scroll, maxScroll));
    if (sel) {
      if (this.at * H < this.scroll) this.scroll = this.at * H;
      if ((this.at + 1) * H > this.scroll + height) this.scroll = (this.at + 1) * H - height;
    }
    const position = (el, i) => (fixed ? el.absolute().left(0).right(0).top(i * H - this.scroll).h(H) : el);
    const visible = (i) => !fixed || ((i + 1) * H > this.scroll && i * H < this.scroll + height);
    const home_ = home();

    const row = (r, i) => {
      const base = h_flex()
        .id(r.kind === "space" ? `sz-${r.s.id}` : `sz-${r.kind}-${r.path ?? r.label}`)
        .mx(4)
        .px(10)
        .h(H)
        .rounded(7)
        .gap(10)
        .items_center()
        .cursor_pointer()
        .when(i === this.at, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.go(r));
      if (r.kind === "space") {
        return base
          .child(h_flex().size(18).flex_none().rounded(5).bg(spaceColor(t, r.s)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...r.s.name][0]?.toUpperCase() ?? "?"))
          .child(div().flex_1().truncate().text_color(t.foreground).when(r.s.active, (d) => d.font_semibold()).child(r.label))
          .when(r.s.active, (el) => el.child(div().text_size(11).text_color(t.dim).child("atual")));
      }
      if (r.kind === "host") {
        return base
          .child(div().w(18).flex_none().text_color(r.tab ? t.foreground : t.muted).child(r.tab ? "*" : "+"))
          .child(div().flex_1().truncate().text_color(t.foreground).child(r.label))
          .when(Boolean(r.tab), (el) => el.child(div().text_size(11).text_color(t.dim).child("aberto")));
      }
      const shown = r.path.startsWith(home_ + "/") ? `~${r.path.slice(home_.length)}` : r.path;
      return base
        .child(div().w(18).flex_none().text_color(t.muted).child("+"))
        .child(div().flex_none().text_color(t.foreground).child(r.label))
        .child(div().flex_1().min_w(0).truncate().text_right().text_size(11).text_color(t.dim).child(shown));
    };

    return v_flex()
      .id("sessionizer")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        const ctrl = e.modifiers.control;
        const n = rows.length;
        if (k === "escape") return this.close();
        if (n && (k === "down" || (ctrl && (k === "n" || k === "j")))) this.at = (this.at + 1) % n;
        else if (n && (k === "up" || (ctrl && (k === "p" || k === "k")))) this.at = (this.at + n - 1) % n;
        else if (ctrl && k === "x") {
          if (sel?.kind === "space" && !sel.s.active) run("space.close", { id: sel.s.id, confirmed: true });
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child(this.ssh ? "SSH" : "Sessionizer")).child(div().id("sz-esc").px(6).py(2).rounded(5).text_size(11).text_color(t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(() => this.close()).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(
        v_flex()
          .id("sz-list")
          .on_size_change((size, cx) => {
            this.listHeight = size.height / settings().zoom;
            cx.notify();
          })
          .h(Math.min(320, total))
          .min_h(0)
          .mb(6)
          .when(fixed, (el) =>
            el.overflow_hidden().on_scroll_wheel((e, cx) => {
              this.scroll = Math.max(0, Math.min(this.scroll - e.delta.y, maxScroll));
              // The selection follows the wheel, so the next frame doesn't scroll back to it.
              while (this.at < rows.length - 1 && this.at * H < this.scroll) this.at++;
              while (this.at > 0 && (this.at + 1) * H > this.scroll + height) this.at--;
              cx.notify();
            }))
          .children(rows.map((r, i) => (visible(i) ? position(row(r, i), i) : null)).filter(Boolean)),
      );
  }
}
