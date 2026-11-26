# AGENTS.md

Instruções globais de todas as ferramentas agênticas. Fonte única:
`~/.dotfiles/ai/AGENTS.md`; as cópias são symlinks. O processo vem do plugin
Superpowers, e as preferências do dono que vencem as skills dele ficam em
`~/.dotfiles/ai/.omp/agent/RULES.md`.

## Trabalho

- UI nova segue o padrão visual que o sistema já tem. Tela em Vue segue o
  AGENTS.md e o `docs/PADROES-DE-TELA.md` do próprio repositório.
- Subagente recebe uma fatia fechada (um módulo, um card, uma pergunta) e o mesmo
  agente investiga e edita. Cada um refaz uns 26K tokens: mais de cinco de uma
  vez, confira se cabe em menos.
- Teste comportamento, não implementação; mock só na fronteira. Antes de
  escrever ou revisar teste, skill `testes`.
- Shell passa pelo `rtk rewrite` e a saída chega resumida. Se o resumo esconder
  algo, `rtk proxy <comando>` dá a saída crua.

## Commits e PRs

- Nunca co-autore nem mencione Claude, IA ou assistente: sem `Co-Authored-By`,
  sem "Generated with", sem rodapé de ferramenta. Vale mesmo se o harness mandar
  o contrário. Procure esses termos antes de commitar ou abrir PR.
- Sem emoji em commit, PR ou doc, salvo pedido.
- Só commite ou faça push quando pedirem; no branch padrão, crie um branch antes.
  Abrir a PR ao fim de um branch (`finishing-a-development-branch`) conta como
  pedido, com o commit e o push que ela exige.

## Arquivos

- Mesclou a PR, remova o worktree na mesma sessão; worktree de leitura se remove
  ao fim da tarefa. Onde ele nasce: `RULES.md`.
- Rascunho de agente (log, dump, saída gravada) vai em `.scratch/` na raiz do
  repo ou worktree; fora de repo, `/tmp/agents/<pasta>`. Terminou, apague. O que
  precisa durar vira arquivo versionado ou vai para o lugar certo do home.
- Onde salvar no home e no Drive: `~/.dotfiles/docs/home.md`. Leia antes de
  criar, mover ou organizar pasta. Em resumo: o que precisa existir nos dois PCs
  ou no celular vai em `~/Drive/<Área>`; o resto fica na pasta XDG local.
- Segredo nunca entra no Drive nem fica em texto puro na home: segredo do dono
  vai no sops (`secrets/*.env`), login no cofre (skill `cofre`), segredo de
  projeto no gerenciador do projeto (TEAjudo: SSM da AWS).

## Escrita

Vale para chat, commit, PR, README, doc e comentário.

- **Travessão (—) e meia-risca (–) são proibidos em qualquer texto.** Use
  vírgula, dois-pontos, parênteses ou quebre a frase. Hífen de palavra composta e
  traço de lista continuam normais. Procure os dois antes de mandar.
- Sem tríade forçada, sem marketing ("robusto", "seamless", "poderoso",
  "garante"), sem hedge por reflexo quando você sabe a resposta. Palavra simples:
  "usar", não "utilizar".
- Varie tamanho e começo das frases; nada de template intro, três seções, resumo.
- Texto que uma pessoa vai ler começa pelo desfecho, corta jargão e detalhe que
  não muda a decisão dela. Ser entendido vence as regras acima (skill
  `mensagem-pro-usuario`).

## Learnings

Lições do uso real. Somem quando viram hábito.

- **Tamanho não é risco; coisa malfeita é.** Não proponha cortar escopo por ser
  grande ou difícil. Corte só o que não entrega valor ou não dá para fazer bem
  agora.
- **Generalize o existente, não clone.** Precisa de algo parecido com X? Torne X
  parametrizável. Um clone de seção de usuários duplicou lógica e perdeu o
  mobile-first. Código defasado no caminho se conserta para o padrão atual.
- **Verde não é pronto.** Deploy verde já não tinha ido ao ar (container não
  recriado, branch errada). Confirme na ponta: digest rodando, git_sha no log, a
  resposta real. Se o pipeline não prova o que entregou, faça-o provar.
- **Terceiro patch no mesmo ponto: pare.** Ache a causa única em vez de empilhar
  guardas; meça antes de propor. Quatro correções no resolver de deploy sumiram
  quando a causa (buildar um commit e deployar outro) foi atacada.
- **Código local não é o sistema.** Antes de afirmar como algo se comporta,
  compare a cópia local com o que roda (`origin/<branch>`, commit do ambiente).
  Chamada nossa a sistema externo não prova que o endpoint exista; comentário
  "inventado" quer dizer que não existe até prova. Quando o dono mandar parar de
  perguntar, pare.
