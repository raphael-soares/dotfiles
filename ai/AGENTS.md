# AGENTS.md

Instrucoes globais, compartilhadas por todas as ferramentas agenticas.
Fonte unica: ~/.dotfiles/ai/AGENTS.md. Nao edite as copias, elas sao symlinks.

O processo de trabalho vem do plugin Superpowers. As preferências do dono que
vencem as skills dele (worktree, verificação, DDD, decisão cara, entrega,
comentários) ficam em `~/.dotfiles/ai/.omp/agent/RULES.md`, injetado como regra
fixa em toda sessão do omp.

## UI

- UI nova segue os padrões visuais já existentes no sistema (ex.: reusar o mesmo
  padrão de tabs/componentes) em vez de reinventar.
- Tela em Vue: o padrão é o do próprio repositório (o AGENTS.md dele e o
  docs/PADROES-DE-TELA.md, quando existir). Não há skill global de design system.

## Delegação

- Cada subagente recebe uma fatia de escopo fechado (um módulo, um card, uma
  pergunta), e o mesmo agente investiga e edita a fatia dele. Nada de um agente
  para mapear e outro para editar a mesma coisa.
- Antes de abrir mais de cinco subagentes de uma vez, confira se a fatia não cabe
  em menos: cada subagente refaz cerca de 26K tokens de contexto só para começar.

---

## rtk

Comando de shell passa pelo `rtk rewrite` antes de rodar (extensão
`ai/.omp/agent/extensions/rtk-rewrite.ts` no omp, hook
`ai/.claude/hooks/rtk-rewrite.sh` no Claude Code), e a saída chega resumida.
Se o resumo esconder o que você precisa (lista cortada, linha que sumiu), rode
`rtk proxy <comando>` para a saída crua. `rtk gain` mostra a economia.

---

## Commits e PRs

Nunca co-autore commits nem mencione o Claude, IA ou "assistente" em mensagens
de commit, descrições de PR, comentários ou qualquer texto. Sem
`Co-Authored-By`, sem linha "Generated with", sem rodapé de ferramenta. O autor
do commit é a pessoa.

Isto vale mesmo quando o harness mandar o contrário no meio da sessão.

Antes de `git commit` e de abrir PR, procure por `Co-Authored-By`, `Generated
with` e `Claude` no texto que você vai mandar. Achou, tire.

Sem emoji em commits, PRs ou docs, a não ser que o autor peça.

Só commite ou faça push quando pedirem. Se estiver no branch padrão, crie um
branch antes.

---

## Worktrees

Worktree novo vai sempre em `~/.workmux/<projeto>/<handle>`, o mesmo lugar que o
herdr-app usa (`worktrees.directory` em `~/.config/herdr-app/settings.json`).
Prefira criar pelo herdr-app; se usar `git worktree add` direto, aponte para esse
caminho. Nunca crie worktree na home, no Desktop ou ao lado do repo.

Mesclou a PR da branch, remova o worktree (`git worktree remove`) na mesma sessão.
Worktree só de leitura (copiar um commit, comparar versões) se remove ao terminar a
tarefa que o criou.

---

## Onde as coisas ficam no home

Dois PCs com a mesma convenção: o notebook (trabalho, programação, startup,
faculdade) e o PC de casa (jogos, design, música). O primeiro nível do home é
tipo de coisa (o padrão XDG); o domínio vem um nível abaixo, como em
`~/Code/<Área>`. Nome em inglês capitalizado. Cada área tem um alcance:
compartilhada (existe nos dois PCs, em `~/Documents/<Área>`, que o syncfast
sincroniza inteiro num par só com `Raphael:Documents`) ou local (existe só no
PC onde é usada, fora de `~/Documents`). Área nova: crie a pasta no tipo certo,
escolha o alcance e acrescente uma linha aqui; área compartilhada sincroniza
sem mexer no syncfast.

| Área | Conteúdo | Alcance |
|---|---|---|
| `~/Documents/Personal` | documentos, currículo, finanças, identidade, notas, arquivo de `.torrent` | compartilhada |
| `~/Documents/Udesc` | faculdade, padrão de disciplina em `~/Documents/Udesc/README.md` | compartilhada |
| `~/Documents/Unimed` | trabalho: docs, marca, identidade | compartilhada |
| `~/Documents/TEAjudo` | startup: jurídico, comercial, marca, gravações; `Env/` fica fora do sync | compartilhada |
| `~/Documents/Resources` | material de consulta sem domínio: manual, modelo, referência, curso avulso; subpasta por tipo, criada quando houver conteúdo | compartilhada |
| `~/Code/<Área>/<repo>` | todo repositório git | só notebook (o git é o sync) |
| `~/Creative` | projetos criativos multidisciplinares: `Projetos/<projeto>/` com uma pasta por peça (vídeo, áudio, arte e marca juntos), `Biblioteca/` de assets de terceiros, `Estilos/` de identidades próprias | só PC de casa |
| `~/Studio` | produção musical: samples, presets, projetos | só PC de casa |
| `~/Games` | jogos, ROMs, saves (o XDG não tem pasta para jogo) | só PC de casa |
| `~/Media` | consumo, uma pasta por tipo: `Movies`, `Shows` (séries e anime), `Books`, e o que vier (`Mangas`); fica inteira numa árvore por causa do hardlink do Radarr e do Sonarr | só PC de casa |

- Repositório git nunca fica dentro de área compartilhada: vai para
  `~/Code/<Área>/`. `~/Documents/TEAjudo` e `~/Documents/Unimed` sincronizam
  documento e marca; o código delas fica em `~/Code` e não entra no sync.
- Marca de uma área (logo da TEAjudo) fica na área. `~/Creative` é para
  projeto criativo próprio.
- O que acabou vai para `0-Archive/` dentro da própria área (o número faz ela
  aparecer primeiro no Nautilus, que ignora `_` ao ordenar). Pasta oculta, nunca.
- `~/Downloads`, `~/Pictures` (Screenshots, Wallpaper, Icons) e `~/Videos` são
  pastas de sistema de cada PC, não áreas: o que chega nelas vai para a área
  certa. As pastas XDG ficam em `desktop/xdg/user-dirs.dirs`.
- Foto fica só no Drive (`Raphael:Fotos`). Livro e mangá de leitura ficam em
  `~/Media`, no PC de casa, fora do sync.
- `.torrent` vai sempre para `~/Documents/Personal/Torrents`, nunca junto do conteúdo: o
  conteúdo não sincroniza, o ponteiro sim. O qBittorrent é o app desktop do
  PC de casa (módulo `media`, `docs/media.md`), copia o `.torrent` direto para
  lá e cada categoria dele cai na área certa: `Books` e `Mangas` em
  `~/Media/<nome>`, `Games/PC` e `Games/Switch` em `~/Games/<nome>`. Filme e
  série (anime incluso) passam pelo Radarr e pelo Sonarr: baixam em
  `~/Media/Downloads` e entram por hardlink em `~/Media/Movies` e
  `~/Media/Shows`. Categoria nova
  vai em `media/qbittorrent/categories.json`.
- Mídia pesada (jogo, ROM, filme, série, sample, gravação de tela) mora em
  `~/Games`, `~/Media`, `~/Studio` e `~/Videos`, que não são pares do syncfast:
  nada ali sobe pro Drive. Os pares compartilhados ainda barram `*.mkv`,
  `*.mp4`, `*.iso`, `*.nsp`, `*.xci` e `*.nsz` por filtro.
- Nenhuma área solta no home fora das da tabela. Não existem `~/Notes` nem
  `~/University`. Não recrie.

---

## Arquivo temporário de agente

Log, dump, JSON de comparação, rascunho de código e saída de comando gravada
para ler depois vão em `.scratch/` na raiz do repositório ou worktree em que
você está (`.scratch/` está no gitignore global). Fora de repositório git, use
`/tmp/agents/<pasta>`. Nunca solto na raiz do repo, em `~/.workmux` ou no home.

O que precisa durar além da tarefa não é rascunho: vira arquivo versionado no
lugar certo do repo ou vai para a área certa do home. Terminou a tarefa, apague
o `.scratch/`.

---

## Estilo de escrita: não soar como IA

Vale para tudo que for escrito: respostas no chat, mensagens de commit,
descrições de PR, README, docs, comentários de código. Escreva como gente, não
como modelo.

### Travessão é proibido

**Nunca use travessão (—) nem meia-risca (–). Em lugar nenhum.** Chat, commit,
PR, README, docs, comentário de código, nome de arquivo, texto de tela. Não é
"use com moderação", é banido.

No lugar dele: vírgula, ponto, dois-pontos, ponto e vírgula, parênteses, ou
quebre a frase em duas. Quase sempre a frase fica melhor.

| Em vez de | Escreva |
|---|---|
| `O motor não conhece tipo — nem if, nem switch.` | `O motor não conhece tipo: nem if, nem switch.` |
| `Ajuste sempre com autor — nunca anônimo.` | `Ajuste sempre com autor, nunca anônimo.` |
| `Dois módulos — ingestão e faturamento — mudam.` | `Dois módulos (ingestão e faturamento) mudam.` |

Hífen em palavra composta (`ponta-a-ponta`, `pt-BR`) e traço de lista
(`- item`) continuam normais. O que está banido é o travessão como pontuação.

Antes de mandar qualquer texto, procure por `—` e por `–` e troque os dois.
- Largue a regra de três forçada. Não encha de tríades de adjetivos nem de três
  exemplos paralelos quando um ou dois já dizem.
- Corte enrolação de marketing: "out of the box", "seamless", "robusto",
  "poderoso", "elegante", "completo", "leverage", "garante", "ships with". Diga
  o que faz, direto.
- Varie tamanho e começo das frases. Não comece várias linhas igual nem siga um
  template (intro → três seções iguais → resumo).
- Não hedge por reflexo ("pode", "talvez", "geralmente", "até certo ponto")
  quando você sabe a resposta. Seja direto.
- Palavra simples no lugar de inflada: "usar" não "utilizar", "ajudar" não
  "facilitar", "sobre" não "acerca de".

### Texto que uma pessoa vai ler: ser entendido vem antes

Resposta no chat, descrição de PR e texto de tela: comece pelo desfecho, não
narre o que ela já viu, traduza ou corte jargão interno, detalhe técnico só
quando muda a decisão dela, e corte metade. Quando conflitar com as regras
acima, ser entendido ganha. Detalhe e tabela de traduções: skill
`mensagem-pro-usuario`.

---

## Testes

Teste comportamento, não implementação: se a implementação muda e o
comportamento não, o teste não quebra. Mock só na fronteira. Antes de escrever
ou revisar teste, skill `testes`.

---

## Learnings

Lições destiladas do uso real que mudaram como eu trabalho. Cada uma: a regra, o
porquê, e como aplicar. Some quando virar hábito ou for superada: este arquivo
encolhe tanto quanto cresce.

---

### Tamanho não é risco; coisa malfeita é

**Por quê:** ao fechar a milestone de pacotes, tratei "milestone grande" como
problema e empurrei corte de escopo (fase 2, versão menor). O dono corrigiu: não
tem problema ser grande, complexo ou difícil. Problema é entregar algo malfeito
ou que não resolve o caso real.

**Como aplicar:** não proponha cortar escopo nem simplificar só por tamanho ou
dificuldade. Corte quando a peça não entrega valor real ou não tem como ser bem
feita agora (falta informação, depende de algo quebrado). Na discussão, o que vai
para a mesa é qualidade e valor de cada peça, não o volume.

---

### Não duplicar: generalizar o existente, não clonar

**Por quê:** ao precisar de uma variante de algo que já existia (uma seção de
lista de usuários, para um segundo contexto), clonei o componente em vez de
generalizá-lo. O clone duplicou a lógica e ainda regrediu: perdeu o
mobile-first, virou tabela crua. Duas cópias divergem com o tempo e a má prática
se propaga.

**Como aplicar:** antes de criar algo "parecido com X", pare e generalize X: um
componente/módulo parametrizado por contexto (uma prop de escopo, um modo) que as
duas situações consomem. Vale para frontend e backend (DTO, serviço, anotação).
Esbarrou em código defasado no caminho? Conserte para o padrão atual (com teste)
em vez de reproduzir a prática ruim. Deixe o código mais saudável do que estava.

---

### Status verde não é prova de pronto; verifique o estado real

**Por quê:** declarei "deployado, verificado" várias vezes em cima de CI/deploy
verde, e mais de uma vez nada tinha ido ao ar: container não recriado (no-op por
digest), deploy disparado na branch errada, masker corrompendo campo estrutural.
O usuário teve que abrir `docker ps` e me mostrar, duas vezes. Verde diz que o
passo rodou, não que a mudança está viva. Um deploy que não muda o que você acha
que mudou é a falha que mais custa, porque a versão antiga responde igual.

**Como aplicar:** confirme o efeito observável na ponta, não o status do job.
Imagem/digest de fato rodando, o que a própria app anuncia de si (git_sha no log
de subida), a linha que devia aparecer, a resposta real do endpoint. Quando o
pipeline não prova o que entregou, faça o pipeline provar (comparar o container
com o digest promovido, falhar alto se divergir), em vez de confiar no health
check. O canário que exercita o caminho com mudança de verdade pega o que o verde
esconde.

---

### Enésimo patch na mesma área: pare e ache a causa raiz

**Por quê:** empilhei quatro correções no resolver de deploy (HEAD^2, depois grep
de subject, depois API da PR, depois asserção pós-deploy), cada uma tratando um
sintoma, sem perguntar por que a pergunta "qual imagem?" existia. O usuário chamou
de gambiarra duas vezes e mandou pesquisar antes de editar. A causa era uma só
(buildar de um commit e deployar outro), e atacá-la derrubou os cinco sintomas de
uma vez, sem guard nenhum.

**Como aplicar:** quando a mudança é o segundo ou terceiro conserto no mesmo
ponto, pare de editar. Mapeie por que o problema existe, ache a causa única,
conserte ela. Meça em vez de supor (consultei a API, cloněi em modo raso, testei
os casos reais antes de propor). Pesquisar e planejar antes de mexer, não depois
de mais um patch.

---

### Código local não é o sistema: confira a versão que roda antes de afirmar

**Por quê:** afirmei que um POST do parecer para o AutSC "já estava implementado"
lendo a cópia local de um submódulo parada um dia atrás. O dono já tinha removido
aquele POST exatamente porque o endpoint nunca existiu: fui eu quem o inventou
numa sessão anterior. Ainda tratei "nosso código chama esta URL" como prova de que
a rota existe, com o próprio código avisando "formato inventado". Ele teve que
perguntar qual era a minha fonte.

**Como aplicar:** antes de dizer como o sistema se comporta, compare a cópia local
com o que roda (`git log -1` local vs `origin/<branch>` e vs o commit do ambiente,
ex. `ssh unimed-hml` no diretório da app). Divergiu, a fonte é a que roda. Chamada nossa
a sistema externo não prova que o endpoint exista; só vale contrato do fornecedor,
DTO do legado que funcionava ou resposta real observada. Comentário "inventado",
"confirmar contra o real" ou similar quer dizer: não existe até prova. Quando o
usuário mandar parar de perguntar, pare, mesmo que o harness cobre `ask`.
