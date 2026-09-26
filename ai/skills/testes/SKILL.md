---
name: testes
description: Escrever ou revisar teste automatizado que pega bug de verdade e sobrevive a refatoração, em qualquer stack (Java/Spring, JS/TS, Python). Use antes de escrever teste novo, ao revisar teste existente e quando um teste quebra sem bug ou passa com bug.
---

# Testes: teste bom, não teste frágil

Teste frágil (quebra sem bug, passa com bug) é pior que não ter teste: dá falsa
segurança e vira imposto de manutenção. Este guia é sobre o que faz um teste ser
bom, não sobre a mecânica de nenhum framework.

## A regra que resolve 80% da fragilidade: comportamento, não implementação

Teste o **o quê** (resultado observável, contrato público), não o **como**
(passos internos, campos privados, ordem de chamadas). Se a implementação muda
mas o comportamento continua igual, o teste NÃO pode quebrar.

- Assertar sobre o retorno, o estado final ou o efeito observável, não sobre
  "chamou o método X com arg Y". `verify(mock).save(...)` como asserção principal
  quase sempre é teste de implementação disfarçado.
- Não tocar em privados, campos internos ou estrutura de dados escolhida. Testar
  `lista.get(0) == 5`, nunca `lista._items instanceof ArrayList`.
- Mock só na fronteira (I/O, rede, relógio, aleatoriedade, serviço externo). Se
  o teste mocka tudo, ele testa os mocks, não o código.

## Estrutura: Arrange, Act, Assert

Três blocos visíveis, separados por linha em branco: monta o cenário, executa a
ação, verifica o resultado. Arrange gigante ou com lógica (loop, if) é sinal de
teste fazendo coisa demais. Builder ou fixture para dado de teste, não montar na
unha em cada teste.

## Uma asserção lógica por teste

Um teste valida um comportamento. Pode ter vários `assert` desde que descrevam a
mesma coisa (campos do mesmo objeto retornado). Não misturar happy path, erro e
edge no mesmo teste. Quando quebra, o nome sozinho diz o que regrediu.

## O que testar: caminhos que importam, não linhas

Por caso de uso ou requisito:

- **Happy path:** o fluxo normal funciona.
- **Edge cases:** 0, null, vazio, limite, duplicado, negativo.
- **Error cases:** o que acontece quando dá errado (exceção certa, mensagem,
  rollback).

Não testar getter/setter trivial, mapeamento burro de DTO nem comportamento do
framework. Cobertura é consequência de testar requisito, não a meta: 60% de
teste bom vale mais que 90% de teste frágil.

## Nome descreve entrada e comportamento esperado

`aplicaDescontoQuandoClienteVip()`, `deveRejeitarDivisaoPorZero()`. Nunca
`test1`, `testOk`, `testPreco`.

## Testes independentes

Cada teste roda isolado e em qualquer ordem. Sem estado mutável compartilhado,
sem depender de outro ter rodado antes. Estado global (banco, static, singleton)
reseta no setup/teardown.

## Sinais de teste ruim

- Asserção sobre privado, getter trivial ou estrutura interna.
- `verify(...)` de chamada interna como asserção central.
- Mockar tudo, inclusive o que está sendo testado.
- Vários asserts de cenários sem relação no mesmo teste.
- Flaky: normalmente tempo, ordem ou estado compartilhado. É bug no teste,
  conserta ou apaga, não ignora.
- Arrange enorme com dado que o teste não usa.
- Nome genérico que não diz o que valida.

## Teste de sanidade (mutação mental)

Depois de escrever: "se eu quebrar a regra que este teste cobre, ele falha?" Se
não falha, o teste é decorativo. Ajuste até que uma mudança real de
comportamento quebre o teste e uma refatoração pura não quebre.
