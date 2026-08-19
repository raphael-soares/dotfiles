# Navegação — Vue/Vuetify

Referência da skill `vue-vuetify`.

---

## Navegação

**App bar (desktop):**
```vue
<v-app-bar height="52" class="border-b-sm" elevation="0">
  <!-- branding: bloco primário com ícone secundário + nome do sistema -->
  <header class="header__branding bg-primary">
    <div class="header__icon bg-secondary">
      <img :src="AppIcon" alt="" width="28" />
    </div>
    <span class="font-weight-bold text-uppercase text-white header__name">
      {{ appName }}
    </span>
  </header>

  <!-- tabs de navegação -->
  <v-tabs v-model="activeTab" color="primary" slider-color="primary" density="compact">
    <v-tab :to="route" :value="id">{{ title }}</v-tab>
    <!-- menus com filhos usam v-menu + v-tab com append-icon="mdi-chevron-down" -->
  </v-tabs>

  <!-- user menu no #append -->
  <template #append>
    <v-tabs color="primary" density="compact">
      <v-menu><template #activator="{ props }"><v-tab v-bind="props">...</v-tab></template></v-menu>
    </v-tabs>
  </template>
</v-app-bar>
```

**CSS do header (sempre scoped):**
```css
.header__branding {
  height: 100%;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding-right: 1rem;
}
.header__icon {
  height: 100%;
  display: flex;
  align-items: center;
  padding: 0 14px;
}
.header__name {
  font-size: 0.8125rem;
  letter-spacing: 0.08em;
}
```

**Regras do header:**
- `hide-slider` NÃO deve ser usado — o slider (underline) é o indicador de tab ativa
- CSS do header deve ser sempre `<style scoped>` para não vazar globalmente
- `.header__icon` usa `height: 100%` para preencher a barra sem overflow artificial
- `text-uppercase` sempre com `letter-spacing: 0.08em` para legibilidade

**App bar (mobile):**
```vue
<v-app-bar height="52" elevation="0" border color="primary">
  <template #prepend>
    <v-btn variant="text" color="white" @click="router.back()">
      <v-icon icon="mdi-arrow-left" />
    </v-btn>
  </template>
  <span class="font-weight-bold text-uppercase text-white mx-auto" style="letter-spacing: 0.08em">
    {{ appName }}
  </span>
  <template #append>
    <v-btn variant="text" color="white" @click="toggleSidebar">
      <v-icon icon="mdi-menu" />
    </v-btn>
  </template>
</v-app-bar>
```

**Sidebar (mobile):**
```vue
<v-navigation-drawer color="primary" temporary location="right">
  <v-list nav density="compact">
    <!-- items -->
  </v-list>
</v-navigation-drawer>
```

**Navigation item type:**
```ts
type NavigationItem = {
  id: string
  title?: string
  icon?: string
  to?: RouteLocationRaw
  children?: NavigationItem[]
  badge?: string | number
  badgeColor?: string
  action?: () => void
  permissions?: string[]
}
```

---

