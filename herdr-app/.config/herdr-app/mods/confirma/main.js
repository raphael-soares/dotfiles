// Diálogo de confirmação com props { title, detail, command: { name, args } }.
// y ou Enter confirmam; n, q ou Esc cancelam.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, theme } from "herdr";

export default class Confirma extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  sim() {
    const p = props();
    closeOverlay(p.overlay);
    run(p.command.name, p.command.args ?? {});
  }

  nao() {
    closeOverlay(props().overlay);
  }

  render(cx) {
    const t = theme();
    const p = props() ?? {};
    const botao = (id, label, tecla, bg, fg, onClick) =>
      h_flex()
        .id(id)
        .h(32)
        .px(14)
        .gap(8)
        .items_center()
        .rounded(8)
        .border_1()
        .border_color(id === "nao" ? t.input : bg)
        .bg(bg)
        .text_color(fg)
        .cursor_pointer()
        .hover((s) => s.opacity(0.88))
        .on_click(onClick)
        .child(label)
        .child(div().text_size(11).opacity(0.6).child(tecla));
    return v_flex()
      .id("confirma")
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "y" || e.key === "enter") this.sim();
        else if (e.key === "n" || e.key === "q" || e.key === "escape") this.nao();
        else return;
        cx.stop_propagation();
      })
      .size_full()
      .min_h(0)
      .p(18)
      .gap(12)
      .rounded(8)
      .bg(t.popover)
      .text_size(13)
      .child(div().text_size(15).font_semibold().text_color(t.foreground).child(p.title ?? "Tem certeza?"))
      .child(div().flex_1().min_h(0).overflow_y_scrollbar().text_color(t.muted).child(p.detail ?? ""))
      .child(
        h_flex()
          .justify_end()
          .gap(8)
          .text_size(12)
          .child(botao("nao", "Cancelar", "n", t.raised, t.foreground, () => this.nao()))
          .child(botao("sim", "Fechar", "y", t.solid, t.solid_foreground, () => this.sim())),
      );
  }
}
