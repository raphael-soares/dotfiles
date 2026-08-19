# Tabelas — Vue/Vuetify

Referência da skill `vue-vuetify`.

---

## Tabelas

```vue
<v-sheet border rounded>
  <v-data-table
    :loading="loading"
    :headers="headers"
    :items="items?.content"
    :items-per-page="items?.size"
    :page="(items?.number ?? 0) + 1"
    @update:items-per-page="$emit('update:items-per-page', $event)"
    @update:page="$emit('update:page', $event - 1)"
    @update:sort-by="$emit('update:sort', $event)"
  >
    <template #item="{ item }">
      <TableRow :item="item" />
    </template>
  </v-data-table>
</v-sheet>
```

**Header definition:**
```ts
const headers = ref<DataTableHeader[]>([
  { title: 'Nome', key: 'nome', align: 'start', width: '60%' },
  { title: 'Status', key: 'status', align: 'start', width: '40%' },
])
```

**Row clicável:**
```vue
<tr class="clickable-row" @click="router.push({ name: RouteNames.DETAIL, params: { id: item.id } })">
  <td>{{ item.nome }}</td>
</tr>

<style scoped>
.clickable-row { cursor: pointer; transition: background-color 0.2s ease; }
.clickable-row:hover { background-color: rgba(0, 0, 0, 0.04); }
</style>
```

---

