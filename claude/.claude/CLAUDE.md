Always respond in English, regardless of the language used in user messages.

## Fluxo de trabalho

- Ao terminar um card, faça uma revisão final antes de abrir PR: o card foi
  atendido 100%, sem problemas deixados para trás, sem código morto, sem
  regressões. Achou algo, já conserte e repita a revisão até não encontrar mais
  nada. Só então abra a PR.

## Interação e UI

- Ao fazer perguntas ao usuário (escolhas, esclarecimentos), usar sempre o input
  interativo (AskUserQuestion), nunca pergunta em texto solto.
- UI nova segue os padrões visuais já existentes no sistema (ex.: reusar o mesmo
  padrão de tabs/componentes) em vez de reinventar.
- Vue/Nuxt + Vuetify: carregue a skill `vue-vuetify` ANTES de criar ou alterar
  qualquer componente, tela ou estilo. Ela é a fonte do design system.

@RTK.md

## Convenções (guidelines)

@guidelines/commits.md
@guidelines/writing-style.md
@guidelines/django-conventions.md
@guidelines/testing.md
@guidelines/learnings.md
