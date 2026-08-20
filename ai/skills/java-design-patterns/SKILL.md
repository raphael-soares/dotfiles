---
name: java-design-patterns
description: Apply or review classic design patterns (Builder, Factory, Strategy, Observer, Decorator, Adapter) in Java/Spring Boot code. Use when a design problem suggests a known pattern, when reviewing code that could be better structured, or when the user asks about patterns/anti-patterns in a Java or Spring service.
---

# Design Patterns (Java / Spring Boot)

Use when a design problem suggests a known pattern, or when reviewing code that
could benefit from better structure.

## When to suggest a pattern

Só aplique um padrão quando ele resolve um problema concreto **atual** — nunca
especulativamente. Pergunte: "esse código tem uma dor que esse padrão elimina?"

---

## Creational patterns

### Builder — construção de objeto complexo

**Quando:** objeto tem muitos campos opcionais, ou a construção tem várias etapas.

```java
// Em vez de um construtor com 7 parâmetros:
public class CreateOrderCommand {
    private final Customer customer;
    private final List<OrderItem> items;
    private final Address shipTo;
    private final String coupon;        // opcional
    private final String note;          // opcional

    private CreateOrderCommand(Builder builder) {
        this.customer = builder.customer;
        this.items = builder.items;
        this.shipTo = builder.shipTo;
        this.coupon = builder.coupon;
        this.note = builder.note;
    }

    public static class Builder {
        // obrigatórios no construtor, opcionais via métodos fluentes
        public Builder note(String note) { /* ... */ return this; }
        public CreateOrderCommand build() { return new CreateOrderCommand(this); }
    }
}
```

**Alternativa Spring:** use um `record` para casos simples; use Builder só quando
realmente precisar.

### Factory — seleção de tipo em runtime

**Quando:** o tipo concreto a criar depende de dado de runtime.

```java
// Ex: gateway de pagamento diferente por provedor
public interface PaymentGatewayClient {
    PaymentResult charge(PaymentRequest request);
    String getProvider();
}

@Component
public class PaymentClientFactory {
    private final Map<String, PaymentGatewayClient> clients;

    public PaymentClientFactory(List<PaymentGatewayClient> clients) {
        this.clients = clients.stream()
            .collect(Collectors.toMap(PaymentGatewayClient::getProvider, c -> c));
    }

    public PaymentGatewayClient get(String provider) {
        return Optional.ofNullable(clients.get(provider))
            .orElseThrow(() -> new ProviderNotSupportedDomainException(provider));
    }
}
```

---

## Behavioral patterns

### Strategy — algoritmos intercambiáveis

**Quando:** várias implementações do mesmo comportamento, escolhidas em runtime.

```java
// Ex: regras de preço diferentes por tipo de cliente
public interface PricingStrategy {
    BigDecimal price(Order order);
}

@Component("standardPricing")
public class StandardPricing implements PricingStrategy { /* ... */ }

@Component("wholesalePricing")
public class WholesalePricing implements PricingStrategy { /* ... */ }

// No service — injete a estratégia certa a partir de configuração
```

### Observer — reagir a eventos de domínio

**Quando:** várias partes do sistema precisam reagir a algo que aconteceu, sem
acoplamento.

```java
// Evento de domínio
public record OrderPlacedEvent(Long orderId, Long customerId) {}

// Publisher (no service)
@Service
public class OrderService {
    private final ApplicationEventPublisher events;

    public OrderResponse place(/* ... */) {
        Order order = repository.save(/* ... */);
        events.publishEvent(new OrderPlacedEvent(order.getId(), order.getCustomerId()));
        return toResponse(order);
    }
}

// Listener (em outro service/módulo)
@Component
public class OrderNotificationListener {
    @EventListener
    @Async
    public void onOrderPlaced(OrderPlacedEvent event) {
        // notifica sem acoplar ao OrderService
    }
}
```

---

## Structural patterns

### Decorator — adicionar comportamento sem alterar a classe

**Quando:** precisa envolver comportamento existente (logging, cache, métricas)
de forma transparente.

```java
// Ex: auditoria em volta de um pagamento
@Primary
@Component
public class PaymentServiceAuditDecorator implements PaymentService {
    private final PaymentService delegate;
    private final AuditService audit;

    @Override
    public PaymentResult charge(PaymentRequest request) {
        PaymentResult result = delegate.charge(request);
        audit.record(request, result);
        return result;
    }
}
```

### Adapter — ligar interfaces incompatíveis

**Quando:** integrar uma API externa que não bate com a interface interna.

```java
// Porta interna
public interface PaymentGatewayClient {
    PaymentResult charge(PaymentRequest request);
}

// Adapter para a API externa
@Component
public class StripeApiAdapter implements PaymentGatewayClient {
    private final StripeClient externalClient;

    @Override
    public PaymentResult charge(PaymentRequest request) {
        StripeChargeRequest external = toExternal(request);
        StripeCharge externalResult = externalClient.charge(external);
        return fromExternal(externalResult);
    }
}
```

---

## Anti-patterns a evitar

| Anti-pattern | Problema | Correção |
|---|---|---|
| Singleton em excesso | Estado global escondido, difícil de testar | Injete como bean do Spring |
| Domain model anêmico | Toda lógica no service, entidades são sacos de dados | Mova regras de negócio para métodos da entidade |
| God service | Um service com 20+ métodos de várias responsabilidades | Divida por responsabilidade coesa |
| Abstração prematura | Interface com uma única implementação "por via das dúvidas" | Comece concreto, extraia a interface quando a segunda implementação aparecer |
