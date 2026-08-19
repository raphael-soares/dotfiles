# Django — convenções de schema

Padrões para projetos Django com schema novo (Django-managed, migrations limpas).
Vale quando a gente controla o schema, não quando espelha um banco legado.

## Nomes de coluna e campo

Nomes limpos em **pt-BR**. Sem prefixo húngaro (o `logevento`, `usuariocodigo`,
`logid` do sistema antigo) e sem inglês (`created_at`, `event`).

- **PK:** `id` UUID, por um mixin `UUIDModel` compartilhado. Não `logid`/`xcodigo`.
- **Timestamps:** `criado_em` (`auto_now_add`) e `atualizado_em` (`auto_now`), por um
  mixin `TimestampedModel`. Modelos de domínio herdam um `BaseModel` que junta os dois.
- **Campos:** nome de domínio direto (`usuario`, `evento`, `mensagem`, `objeto`), sem
  repetir o nome da tabela como prefixo.
- **Texto sem `null`:** campo de string usa `blank=True, default=""`, nunca `null=True`
  (regra do ruff `DJ001`). `null=True` só em campo não-texto.

Por quê: consistência pt-BR com o resto do código e das telas, e um schema legível sem
o ruído do estilo húngaro. UUID como PK acompanha o que os projetos já vinham usando.

Mixins base (`UUIDModel`, `TimestampedModel`, `BaseModel`) moram no app `core`/compartilhado
e são herdados pelos apps de domínio.
