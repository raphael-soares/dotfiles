---
name: django-schema
description: Convenções de schema para projeto Django com schema novo (Django-managed, migrations limpas): nome de campo em pt-BR, PK UUID, timestamps e mixins base. Use ao criar ou alterar model, campo ou migration num projeto Django que controla o próprio schema. Não vale para model que espelha banco legado.
---

# Django: convenções de schema

Vale quando o projeto controla o schema, não quando espelha um banco legado.

## Nomes de coluna e campo

Nomes limpos em **pt-BR**. Sem prefixo húngaro (o `logevento`, `usuariocodigo`,
`logid` do sistema antigo) e sem inglês (`created_at`, `event`).

- **PK:** `id` UUID, por um mixin `UUIDModel` compartilhado. Não `logid`/`xcodigo`.
- **Timestamps:** `criado_em` (`auto_now_add`) e `atualizado_em` (`auto_now`), por
  um mixin `TimestampedModel`. Modelos de domínio herdam um `BaseModel` que junta
  os dois.
- **Campos:** nome de domínio direto (`usuario`, `evento`, `mensagem`, `objeto`),
  sem repetir o nome da tabela como prefixo.
- **Texto sem `null`:** campo de string usa `blank=True, default=""`, nunca
  `null=True` (regra do ruff `DJ001`). `null=True` só em campo não-texto.

Por quê: consistência pt-BR com o resto do código e das telas, e um schema
legível sem o ruído do estilo húngaro. UUID como PK acompanha o que os projetos
já vinham usando.

## Onde moram os mixins

`UUIDModel`, `TimestampedModel` e `BaseModel` ficam no app `core` (ou o app
compartilhado do projeto) e são herdados pelos apps de domínio.
