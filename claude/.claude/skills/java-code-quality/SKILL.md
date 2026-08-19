---
name: java-code-quality
description: Systematic code review of Java/Spring Boot code — Clean Code (DRY/KISS/YAGNI), HTTP/REST semantics, DTOs vs entities, null safety, exception handling, transactions, JPA, naming, dependency injection. Use when reviewing a Spring Boot change, a PR, or a service/controller before commit.
---

# Code Quality Review (Java / Spring Boot)

Revisão sistemática de código Java/Spring Boot.

## Fase 1 — Entender o escopo

Antes de revisar, identifique:
- A que módulo/área o código pertence?
- É feature nova, correção ou refactor?
- O projeto tem invariantes próprios (multi-tenant, SSOT, etc.)? Eles estão no
  `CLAUDE.md` do repo — leia antes, porque mudam o que é "crítico" aqui.

## Fase 2 — Avaliar por categoria

### Clean Code

**DRY (Don't Repeat Yourself)**
- [ ] Sem lógica de negócio duplicada entre services
- [ ] DTOs compartilhados em um `shared/dto/` quando usados por vários módulos
- [ ] Exceções de domínio comuns em um `shared/exception/`

**KISS (Keep It Simple)**
- [ ] Cada método faz uma coisa
- [ ] Sem abstração prematura (helper para um único caso de uso)
- [ ] Controller é fino: valida → chama service → mapeia resposta

**YAGNI (You Aren't Gonna Need It)**
- [ ] Sem parâmetro, campo ou método não usado
- [ ] Sem generalização especulativa ("talvez a gente precise depois")

### Contrato da API

**Semântica HTTP:**
- [ ] `GET` para leitura, `POST` para criar, `PUT`/`PATCH` para atualizar, `DELETE` para remover
- [ ] `201 Created` em POST com sucesso, `204 No Content` em DELETE com sucesso
- [ ] `400` para erro de validação, `404` para recurso ausente, `403` para falha de autorização
- [ ] Formato de erro consistente via um handler global → um DTO de erro único

**DTOs vs entidades:**
- [ ] Nenhuma classe `@Entity` retornada de endpoint
- [ ] Request DTOs são `record`, nomeados `NomeRequest`
- [ ] Response DTOs são `record`, nomeados `NomeResponse`
- [ ] Sem ID interno que habilite IDOR nas respostas (prefira chaves de negócio)

### Boas práticas Java

**Null safety:**
- [ ] `Optional` retornado das queries, desembrulhado com `.orElseThrow()`
- [ ] Sem `null` cru retornado de método de service
- [ ] `@NotNull`/`@NotBlank`/`@Valid` nos campos de DTO e parâmetros de controller

**Tratamento de exceção:**
- [ ] Exceções de domínio estendem `RuntimeException`, nomeadas `NomeDomainException`
- [ ] Todas mapeadas no handler global — nunca no controller
- [ ] Sem `catch (Exception e)` engolindo exceção em silêncio

**Transações:**
- [ ] `@Transactional` na classe ou método de service, nunca no controller
- [ ] `@Transactional(readOnly = true)` em todo método de leitura
- [ ] Sem acesso a associação lazy fora de transação

**JPA:**
- [ ] Todos os relacionamentos usam `FetchType.LAZY`
- [ ] Sem N+1 (cheque com log de SQL se estiver na dúvida)
- [ ] Queries respeitam os invariantes de tenant do projeto, se houver

**Nomenclatura:**
| Tipo | Convenção |
|---|---|
| Entity | `Order` |
| Repository | `OrderRepository` |
| Service | `OrderService` |
| Controller | `OrderController` |
| Request DTO | `CreateOrderRequest` |
| Response DTO | `OrderResponse` |
| Domain exception | `SlotTakenDomainException` |

**Injeção de dependência:**
- [ ] Só injeção por construtor — sem `@Autowired` em campo
- [ ] Sem dependência circular

## Fase 3 — Classificar achados

| Severidade | Exemplos |
|---|---|
| **Crítico** | Vazamento de tenant (filtro ausente em app multi-tenant), `@Entity` na resposta, exceção não tratada vazando stack trace |
| **Importante** | N+1, `@Transactional` ausente, `@Transactional` no controller, injeção em campo |
| **Menor** | Desvio de nomenclatura, `readOnly=true` faltando, null check desnecessário |
| **Positivo** | DTO bem desenhado, transação bem escopada, boa exceção de domínio |

## Formato de saída

Para cada achado:
```
[SEVERIDADE] Arquivo:Linha — Descrição
Problema: <o que está errado>
Correção:
<trecho corrigido>
```

Feche com uma tabela-resumo por severidade e um veredito geral.
