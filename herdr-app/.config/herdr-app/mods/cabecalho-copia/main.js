import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme } from "herdr";

// Header dos panes no layout `<nome>-copia`, que só existe enquanto o modo cópia está aberto.
export default class CabecalhoCopia extends View {
  render() {
    const t = theme();
    const dica = (tecla, oque) =>
      h_flex().gap(4).items_center()
        .child(div().px(5).rounded(4).bg("#ffffff0f").text_color(t.foreground).child(tecla))
        .child(div().text_color(t.dim).child(oque));
    return h_flex()
      .size_full()
      .pl(12)
      .pr(12)
      .gap(8)
      .items_center()
      .text_size(13)
      .child(svg("mods/cabecalho-copia/copy.svg").size(15).flex_none().text_color(t.blocked))
      .child(div().flex_1().font_semibold().text_color(t.blocked).child("Copy mode"))
      .child(h_flex().gap(12).child(dica("v", "select")).child(dica("y", "copy")).child(dica("q", "quit")));
  }
}
