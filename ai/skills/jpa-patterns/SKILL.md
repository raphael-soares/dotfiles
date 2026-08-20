---
name: jpa-patterns
description: Fix and prevent JPA/Hibernate performance and correctness problems in Spring Data JPA — N+1 queries, LazyInitializationException, fetch strategy, transaction boundaries, pagination, optimistic locking. Use when there are too many SQL statements in logs, lazy-loading errors, slow queries, or @Transactional not behaving as expected.
---

# JPA Patterns (Spring Data JPA / Hibernate)

Use diante de problemas de performance JPA, lazy loading, erros de transação, ou
ao otimizar queries.

## Quando aplicar

- N+1 detectado (SQL demais nos logs)
- `LazyInitializationException` em produção ou testes
- Escolher a estratégia de fetch de um relacionamento
- Problema de fronteira de transação (`@Transactional` não funcionando como esperado)
- Query lenta a otimizar

---

## Pattern 1 — N+1 Queries

**Sintoma:** uma query para buscar a lista + uma query por elemento para buscar
uma associação.

**Diagnóstico:** ligue o log de SQL temporariamente:
```yaml
logging.level.org.hibernate.SQL: DEBUG
logging.level.org.hibernate.orm.jdbc.bind: TRACE
```

**Fix A — JOIN FETCH (JPQL):**
```java
@Query("SELECT o FROM Order o JOIN FETCH o.customer WHERE o.status = :status")
List<Order> findByStatusWithCustomer(@Param("status") OrderStatus status);
```

**Fix B — @EntityGraph (declarativo):**
```java
@EntityGraph(attributePaths = {"customer", "items"})
List<Order> findByStatus(OrderStatus status);
```

**Fix C — @BatchSize (associações de coleção):**
```java
@OneToMany(mappedBy = "order", fetch = FetchType.LAZY)
@BatchSize(size = 20)
private List<OrderItem> items;
```

JOIN FETCH para associações obrigatórias, @EntityGraph para carregamento
opcional, @BatchSize para coleções.

---

## Pattern 2 — Lazy Loading fora da transação

**Sintoma:** `LazyInitializationException: could not initialize proxy - no Session`

**Causa:** acesso a uma associação lazy depois que a transação fechou (ex: no
controller, ou depois que o método do service retornou).

**Fix A — carregue dentro da transação:**
```java
@Transactional(readOnly = true)
public OrderResponse find(Long id) {
    Order order = repository.findById(id)
        .orElseThrow(() -> new OrderNotFoundDomainException(id));
    // mapeie para DTO aqui, com a transação ainda aberta
    return toResponse(order);
}
```

**Fix B — use projections ou DTOs já na query:**
```java
@Query("SELECT new com.example.order.dto.OrderSummary(o.id, o.placedAt, c.name) " +
       "FROM Order o JOIN o.customer c WHERE o.status = :status")
List<OrderSummary> findSummaryByStatus(@Param("status") OrderStatus status);
```

Nunca use `FetchType.EAGER` como correção — degrada performance globalmente.

---

## Pattern 3 — Otimização de query

**Paginação (sempre pagine listas grandes):**
```java
@Transactional(readOnly = true)
public Page<OrderResponse> list(Pageable pageable) {
    return repository.findAll(pageable).map(this::toResponse);
}
```

**Projections (busque só as colunas necessárias):**
```java
public interface OrderProjection {
    Long getId();
    LocalDateTime getPlacedAt();
    String getCustomerName();
}

List<OrderProjection> findProjectedByStatus(OrderStatus status);
```

**Transações read-only (evita overhead de dirty checking):**
```java
@Transactional(readOnly = true)
public List<OrderResponse> list() { /* ... */ }
```

---

## Pattern 4 — Fronteiras de transação

**Transação no nível do service (correto):**
```java
@Service
@Transactional  // default para operações de escrita
public class OrderService {

    @Transactional(readOnly = true)  // override para leitura
    public OrderResponse find(Long id) { /* ... */ }

    public OrderResponse place(CreateOrderRequest request) { /* ... */ }
}
```

**Erros comuns:**
```java
// ERRADO — @Transactional no controller não faz nada de útil
@Transactional
@PostMapping
public ResponseEntity<?> place(/* ... */) { /* ... */ }

// ERRADO — chamar método @Transactional dentro do mesmo bean ignora o proxy
public void publicMethod() {
    transactionalMethod();  // transação NÃO inicia
}
```

**Workaround de self-invocation:** extraia o método interno para outro `@Service`.

---

## Pattern 5 — Optimistic Locking (modificações concorrentes)

```java
@Entity
public class Order {
    @Version
    private Long version;  // o Hibernate gerencia automaticamente
}
```

Trate no service:
```java
try {
    return repository.save(order);
} catch (OptimisticLockingFailureException e) {
    throw new ConcurrentModificationDomainException("Pedido foi modificado por outro usuário");
}
```

---

## Regras que vêm do projeto

Alguns invariantes de query não são genéricos — dependem do projeto. Confira no
`CLAUDE.md` do repo antes de revisar. Os mais comuns:

- **Multi-tenant:** se o app é multi-tenant, **toda** query de entidade
  operacional filtra pelo tenant (vindo do contexto de auth, nunca do request).
  Algumas entidades podem ser explicitamente fora desse eixo — o `CLAUDE.md` diz
  quais.
- **Fetch:** padronize `FetchType.LAZY` em todos os relacionamentos; use JOIN
  FETCH ou @EntityGraph quando precisar. **Nunca** `FetchType.EAGER` — o impacto
  atinge todos os callers.
