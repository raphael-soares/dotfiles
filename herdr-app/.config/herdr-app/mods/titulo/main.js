import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, theme } from "herdr";

export default class Titulo extends View {
  render() {
    const t = theme();
    const nome = spaces().find((s) => s.active)?.name ?? "";
    return h_flex().size_full().bg(t.chrome).pl(14).pr(10).items_center().text_size(13.5)
      .child(div().font_semibold().truncate().text_color(t.foreground).child(nome));
  }
}
