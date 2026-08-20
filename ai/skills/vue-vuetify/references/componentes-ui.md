# Componentes de UI — Vue/Vuetify

Referência da skill `vue-vuetify`.

---

## Componentes de UI

Sempre criar e reutilizar estes componentes em `src/shared/components/ui/`:

### Tipografia

```vue
<!-- TextTitle.vue — títulos de cards e páginas -->
<div class="text-h6 font-weight-bold text-title"><slot /></div>
<!-- scoped style: letter-spacing: -0.01em; line-height: 1.4 -->

<!-- TextSubtitle.vue — subtítulos e descrições -->
<div class="text-subtitle-1 text-medium-emphasis"><slot /></div>

<!-- TextLabel.vue — rótulos de campos, aceita prop icon -->
<div class="text-subtitle-2 font-weight-bold d-flex align-center" v-bind="attrs">
  <v-icon v-if="icon" :icon="icon" size="16" class="mr-1" />
  <slot />
</div>

<!-- TextItem.vue — label + valor para display de dados -->
<div class="text-item">  <!-- scoped style: flex-direction: column; gap: 2px -->
  <TextLabel>{{ label }}</TextLabel>
  <span class="text-body-2 text-medium-emphasis"><slot /></span>
</div>
```

**Regras críticas:**
- Usar `div` em todos (nunca `h1` fora de contexto semântico real)
- `text-medium-emphasis` nos valores e subtítulos para hierarquia visual
- `v-bind="attrs"` no TextLabel para herdar atributos do pai
- `letter-spacing: -0.01em` no TextTitle para toque moderno
- `letter-spacing: 0.08em` em qualquer texto `text-uppercase`

### AppCard

Card padrão para agrupar conteúdo:

```vue
<!-- AppCard.vue -->
<v-card elevation="0" border class="px-2 py-3">
  <v-card-title class="mb-3 d-flex align-center justify-space-between">
    <div class="d-flex align-center">
      <v-icon :icon="icon" :color="iconColor || 'primary'" size="24" class="mr-1" />
      <TextTitle>{{ title }}</TextTitle>
    </div>
    <slot name="header-end" />
  </v-card-title>
  <v-card-text><slot /></v-card-text>
  <v-card-actions><slot name="actions" /></v-card-actions>
</v-card>
```

Props: `icon` (mdi string), `title`, `iconColor` (padrão: 'primary').

### Footer

Barra de ações fixa no rodapé:

```vue
<!-- Footer.vue -->
<v-footer app height="3.5rem" class="px-4 d-flex align-center justify-space-between">
  <div class="d-flex ga-2"><slot name="start" /></div>
  <div class="d-flex ga-2"><slot name="end" /></div>
</v-footer>
```

### Status chips

```vue
<!-- StatusChip.vue -->
<!-- PENDENTE → orange, APROVADA → green, RECUSADA → red -->
<v-chip :color="statusColor[status]" variant="tonal" size="small">
  {{ statusLabel[status] }}
</v-chip>

<!-- ActiveChip.vue -->
<v-chip :color="active ? 'success' : 'error'" variant="tonal" size="small">
  {{ active ? 'Ativo' : 'Inativo' }}
</v-chip>
```

---

