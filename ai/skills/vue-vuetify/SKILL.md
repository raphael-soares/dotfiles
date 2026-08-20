---
name: vue-vuetify
description: Design system e padrões de construção de tela para Vue 3 + Nuxt 3 + Vuetify 3 (tema, defaults de componentes, estrutura de página, botões, espaçamento, convenções). Use SEMPRE antes de criar ou alterar qualquer componente, tela, formulário, tabela, diálogo ou estilo em projeto Vue/Vuetify, para que a UI nova siga o padrão existente em vez de reinventar.
---

# Vue/Nuxt + Vuetify Design System

Padrões visuais e de construção de telas para projetos com **Vue 3 + Nuxt 3 + Vuetify 3**. Seguir este guia garante consistência visual entre todos os projetos da stack.

## Referências — carregue conforme a tarefa

| Arquivo | Quando ler |
|---|---|
| `references/componentes-ui.md` | Tipografia (TextTitle/TextLabel/TextItem), AppCard, Footer, chips de status |
| `references/formularios.md` | Formulário, validação vee-validate + Yup, grid responsivo |
| `references/tabelas.md` | `v-data-table`, headers, paginação server-side, linha clicável |
| `references/dialogos-e-notificacoes.md` | `v-dialog` (confirmação/formulário), snackbar |
| `references/navegacao.md` | App bar desktop e mobile, tabs, sidebar, menu de usuário |

O que está abaixo vale para toda tarefa de UI.

---
## Stack

- Vue 3.5.x + Nuxt 3 + Vuetify 3.9.x + Vite
- Material Design Icons (MDI) — prefixo `mdi-`
- vee-validate + Yup — formulários e validação
- Pinia + pinia-plugin-persistedstate — estado global
- Locale: **pt-BR**

---

## Tema

### Configurar em `src/shared/lib/vuetify/theme.ts`

**Light theme:**
```ts
colors: {
  primary: '#2563EB',        // Azul vibrante — CTA principal
  secondary: '#1E40AF',      // Azul profundo
  accent: '#22D3EE',         // Cyan — detalhes
  success: '#16A34A',        // Verde limpo
  info: '#0EA5E9',           // Azul claro informativo
  warning: '#F59E0B',        // Âmbar
  error: '#DC2626',          // Vermelho forte
  background: '#F8FAFC',     // Cinza muito claro
  surface: '#FFFFFF',        // Branco puro
  'surface-variant': '#E2E8F0',
  'on-background': '#0F172A',
  'on-surface': '#1E293B',
  'on-primary': '#FFFFFF',
}
```

**Dark theme:**
```ts
colors: {
  primary: '#2563EB',
  secondary: '#1E40AF',
  accent: '#22D3EE',
  success: '#33D17A',
  info: '#62A0EA',
  warning: '#F6D32D',
  error: '#ED333B',
  background: '#1E1E1E',
  surface: '#2A2A2A',
  'surface-variant': '#3A3A3A',
  'surface-bright': '#454545',
  'on-background': '#EDEDED',
  'on-surface': '#E5E5E5',
  'on-surface-variant': '#C0C0C0',
  'on-primary': '#FFFFFF',
  outline: '#4F4F4F',
  'outline-variant': '#3A3A3A',
}
```

**Design flat — remover todas as sombras:**
```ts
// No tema Vuetify
shadows: {
  key: { umbra: '...', penumbra: '...', ambient: '...' }
  // Zerar ou remover para design sem sombra
}
```

---

## Defaults de componentes

### Configurar em `src/shared/lib/vuetify/defaults.ts`

```ts
export default {
  VTextField: {
    density: 'compact',
    variant: 'outlined',
    persistentPlaceholder: true,
    persistentHint: true,
  },
  VTextarea: {
    density: 'compact',
    variant: 'outlined',
    persistentPlaceholder: true,
    persistentHint: true,
  },
  VSelect: {
    density: 'compact',
    variant: 'outlined',
    persistentPlaceholder: true,
    persistentHint: true,
  },
  VAutocomplete: {
    density: 'compact',
    variant: 'outlined',
    persistentPlaceholder: true,
    persistentHint: true,
  },
  VDateInput: {
    density: 'compact',
    variant: 'outlined',
    persistentPlaceholder: true,
    persistentHint: true,
  },
  VNumberInput: {
    density: 'compact',
    variant: 'outlined',
    persistentPlaceholder: true,
    persistentHint: true,
  },
  VBtn: {
    variant: 'tonal',
  },
  VDataTable: {
    itemsPerPageOptions: [5, 10, 25, 50],
  },
  VMenu: {
    elevation: 0,
  },
  VList: {
    padding: '0 0',
  },
}
```

---

## Estrutura de página

Toda página segue o padrão: container de conteúdo + footer fixo de ações.

```vue
<template>
  <v-container class="d-flex flex-column ga-4">
    <TextTitle>Título da Página</TextTitle>

    <AppCard icon="mdi-account" title="Nome da Seção">
      <!-- conteúdo da seção -->
    </AppCard>

    <AppCard icon="mdi-information" title="Outra Seção">
      <!-- mais conteúdo -->
    </AppCard>
  </v-container>

  <Footer>
    <template #start>
      <v-btn color="grey" @click="goBack">Voltar</v-btn>
    </template>
    <template #end>
      <v-btn color="grey" @click="reset">Limpar</v-btn>
      <v-btn color="primary" :loading="loading" :disabled="!valid" @click="save">
        Salvar
      </v-btn>
    </template>
  </Footer>
</template>
```

---

## Botões — referência rápida

| Contexto | `color` | `variant` |
|---|---|---|
| Ação primária (Salvar, Criar) | `primary` | `tonal` |
| Cancelar / Voltar / Limpar | `grey` | `tonal` |
| Ação destrutiva (Deletar) | `red` | `tonal` |
| Item de menu | qualquer | `text` |
| Botão ícone | — | `text` |

---

## Espaçamento

Base spacer: **4px** (padrão Vuetify).

| Classe | Valor |
|---|---|
| `ga-1` | 4px |
| `ga-2` | 8px |
| `ga-4` | 16px |
| `px-2 py-3` | padding padrão de card |
| `px-4` | padding de container/footer |
| `my-3` | margem vertical de divider |
| `mr-1` | espaço icon → texto |

---

## Loading global

```vue
<!-- Barra de progresso no topo da página -->
<div class="loading-container">
  <v-progress-linear v-if="isLoading" indeterminate color="primary" />
</div>

<style scoped>
.loading-container { height: 16px; }
</style>
```

---

## Utilitários de layout

Classes Vuetify mais usadas:
```
d-flex flex-column flex-row flex-grow-1
align-center justify-space-between justify-center justify-md-end
ga-2 ga-4
border border-b-sm border-t-sm
```

---

## Convenções gerais

- **Sem sombras** — usar `elevation="0"` + `border` em todos os cards/sheets
- **Densidade compact** em todos os campos de formulário e listas
- **Flat design** — menus sem elevation, listas sem padding
- **Idioma pt-BR** — textos, labels, meses, validações em português
- **Ícones MDI** — usar sempre `mdi-nome-do-icone`
- **Cor de ícone de card** — padrão `primary`, override via prop `icon-color`
- **Paginação server-side** — tabelas emitem eventos, não controlam estado internamente
