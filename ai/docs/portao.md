# Portão: contrato

1. Uma entrada por repositório: `scripts/portao`. Hook e CI chamam essa entrada. Não existe verificação que só roda no CI.
2. Saída 0 limpo, 1 violação, 2 erro de ferramenta. Erro nunca vira limpo.
3. Nenhuma variável desliga bloco ou regra.
4. Arquivo novo é cobrado inteiro; arquivo antigo, nas linhas que a PR escreveu.
5. Exceção é linha num arquivo versionado, com quem decidiu e o motivo. Aparece no diff.
6. Blocos têm nome fixo: formato, estatica, tamanho, teste, mutacao, arquitetura, contrato, migration, termos, morto, segredo, dependencia. Bloco que não se aplica vai em `nao_se_aplica` no `ficha.json`, com motivo; bloco que falta vai em `pendente`, com a issue.
7. Cada violação diz arquivo, regra e o que fazer.

`ficha.json` na raiz: `fila`, `integracao`, `producao` (vazio quando a integração já é a produção), `portao`, `rapido`, `prova`, `nao_se_aplica`, `pendente`, `extras`, `prefixo_de_skill`. Repositório que só guarda a fila declara `fila`, `repos` e `prefixo_de_skill`.

Repositório sem portão que só quer fila ou board (projeto pessoal) declara `fila` e `integracao`; o `fluxo-desvio` não cobra dele os campos do portão. Qualquer `ficha.json` com `fila` aceita `quadro`: a URL do GitHub Project do repo, que o `quadro criar` grava e o `quadro sync` atualiza a partir do estado das issues.
