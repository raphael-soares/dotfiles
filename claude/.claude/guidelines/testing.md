# Testes — escrever teste bom, não teste frágil

Vale pra qualquer stack (Java/Spring, JS/TS, Python). O objetivo é teste que
pega bug de verdade e sobrevive a refatoração. Teste frágil (quebra sem bug,
passa com bug) é pior que não ter teste: dá falsa segurança e vira imposto de
manutenção. Este guia é sobre o que faz um teste ser bom, não sobre a mecânica
de nenhum framework em particular.

## A regra que resolve 80% da fragilidade: teste comportamento, não implementação

Teste o **o quê** (resultado observável, contrato público), não o **como**
(passos internos, campos privados, ordem de chamadas). Se a implementação muda
mas o comportamento continua igual, o teste NÃO pode quebrar.

- Assertar sobre o retorno / estado final / efeito observável, não sobre "chamou
  o método X com arg Y". `verify(mock).save(...)` como asserção principal quase
  sempre é teste de implementação disfarçado.
- Não tocar em privados, campos internos ou estrutura de dados escolhida. Testar
  `lista.get(0) == 5`, nunca `lista._items instanceof ArrayList`.
- Mock só na fronteira (I/O, rede, relógio, aleatoriedade, serviço externo). Se
  o teste mocka tudo, ele testa os mocks, não o código. Over-mock é o sintoma
  número um de teste que não pega bug.

## Estrutura: Arrange–Act–Assert

Três blocos visíveis, um por linha em branco: monta o cenário, executa a ação,
verifica o resultado. Se o Arrange é gigante ou tem lógica (loop, if), o teste
está fazendo coisa demais. Usar builder/fixture pra dado de teste, não montar na
unha em cada teste.

## Uma asserção lógica por teste

Um teste valida um comportamento. Pode ter vários `assert` desde que todos
descrevam a mesma coisa (ex.: campos do mesmo objeto retornado). Não misturar
happy path + erro + edge no mesmo teste. Quando quebra, o nome do teste sozinho
tem que dizer o que regrediu.

## O que testar: caminhos que importam, não linhas

Por caso de uso / requisito, cobrir:
- **Happy path** — fluxo normal funciona.
- **Edge cases** — 0, null, vazio, limite, duplicado, negativo.
- **Error cases** — o que acontece quando dá errado (exceção certa, mensagem,
  rollback).

Não testar getter/setter trivial, mapeamento burro de DTO, nem comportamento do
framework. Foco em regra de negócio. Cobertura é consequência de testar
requisito, não a meta: 60% de teste bom vale mais que 90% de teste frágil.

## Nome descreve entrada + comportamento esperado

`aplicaDescontoQuandoClienteVip()` ou `deveRejeitarDivisaoPorZero()`. Nunca
`test1`, `testOk`, `testPreco`. O nome é a documentação que roda.

## Testes independentes

Cada teste roda isolado e em qualquer ordem. Sem estado compartilhado mutável
entre testes, sem depender de outro ter rodado antes. Estado global (banco,
static, singleton) reseta no setup/teardown.

## Red flags — se aparecer, o teste provavelmente é ruim

- Assertar sobre privados, getters triviais ou estrutura interna.
- `verify(...)` de chamada interna como asserção central (testa o "como").
- Mockar tudo, inclusive o que está sendo testado.
- Vários asserts de cenários sem relação no mesmo teste.
- Flaky (às vezes passa, às vezes falha) — normalmente tempo, ordem ou estado
  compartilhado. Flaky é bug no teste, conserta ou apaga, não ignora.
- Arrange enorme com dado que o teste não usa.
- Nome genérico que não diz o que valida.

## Teste de sanidade rápido (mental mutation test)

Depois de escrever, pergunte: "se eu inverter/quebrar a regra que este teste
cobre, ele falha?" Se não falha, o teste é decorativo. Ajuste até que uma
mudança real no comportamento quebre o teste, e uma refatoração pura não quebre.
