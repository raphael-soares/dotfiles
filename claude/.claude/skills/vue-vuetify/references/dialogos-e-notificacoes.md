# Diálogos e notificações — Vue/Vuetify

Referência da skill `vue-vuetify`.

---

## Diálogos

```vue
<!-- Confirmação destrutiva -->
<v-dialog v-model="open" max-width="480">
  <AppCard icon="mdi-delete-alert" icon-color="red" title="Tem certeza?">
    <p class="text-body-2">Essa ação não pode ser desfeita.</p>
    <template #actions>
      <v-btn variant="tonal" color="grey" @click="open = false">Cancelar</v-btn>
      <v-btn variant="tonal" color="red" @click="confirm">Confirmar</v-btn>
    </template>
  </AppCard>
</v-dialog>

<!-- Diálogo com formulário -->
<v-dialog v-model="open" max-width="720">
  <AppCard icon="mdi-pencil" title="Editar item">
    <FormComponent ref="formRef" @submit="handleSubmit" />
    <template #actions>
      <v-btn variant="tonal" color="grey" @click="open = false">Cancelar</v-btn>
      <v-btn variant="tonal" color="primary" :disabled="!formRef?.valid" @click="formRef?.submitForm">
        Confirmar
      </v-btn>
    </template>
  </AppCard>
</v-dialog>
```

**Tamanhos:** `width="auto"` (pequeno), `max-width="480"` (médio), `max-width="720"` (grande com formulário).

---

## Notificações (Snackbar)

```vue
<!-- App.vue -->
<v-snackbar-queue
  v-model="messages.queue"
  closable
  location="bottom right"
  timeout="5000"
  variant="tonal"
  opacity="30"
  style="margin-bottom: 100px"
/>
```

Store de mensagens:
```ts
type SnackbarItem = { text: string; color: 'info' | 'warning' | 'error' | 'success' }
const queue = ref<SnackbarItem[]>([])
const push = (item: SnackbarItem) => queue.value.push(item)
```

---

