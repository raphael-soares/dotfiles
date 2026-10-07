---
name: use-lsp
description: "Use lsp for code navigation and renames in Java and Vue/TS; stop and report if the server is missing"
alwaysApply: true
---

Para achar e renomear código, use `lsp` (`references`, `definition`, `rename`, `rename_file`, `diagnostics`). Quando ele vier como device, escreva o JSON em `xd://lsp`. Antes de uma issue em Java ou Vue, rode `lsp` com `action: "status"`; se o servidor da peça não aparecer, pare e relate, não volte para grep e reescrita. Agente sem a ferramenta `lsp` (o `scout`) segue com grep.
