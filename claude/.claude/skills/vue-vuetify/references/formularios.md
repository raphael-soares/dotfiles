# Formulários — Vue/Vuetify

Referência da skill `vue-vuetify`.

---

## Formulários

Usar **vee-validate** com schema **Yup**. Padrão de exposição de API via `defineExpose`.

```vue
<template>
  <v-form @submit.prevent="submitForm">
    <v-row dense>
      <v-col cols="12" md="6">
        <v-text-field
          v-model="name"
          label="Nome"
          :error-messages="errors.name"
        />
      </v-col>
      <v-col cols="12" md="6">
        <v-text-field
          v-model="email"
          label="E-mail"
          :error-messages="errors.email"
        />
      </v-col>
    </v-row>
  </v-form>
</template>

<script setup lang="ts">
import { useForm } from 'vee-validate'
import * as yup from 'yup'

const emit = defineEmits<{ submit: [payload: FormPayload] }>()

const schema = yup.object({ name: yup.string().required(), email: yup.string().email().required() })
const { errors, handleSubmit, resetForm, meta } = useForm({ validationSchema: schema })

const loading = ref(false)
const submitForm = handleSubmit(async (values) => {
  loading.value = true
  emit('submit', values)
  loading.value = false
})

defineExpose({ valid: computed(() => meta.value.valid), loading, resetForm, submitForm })
</script>
```

**Layout de grid responsivo padrão:**
- Mobile: `cols="12"` (full width)
- Tablet+: `md="6"` (metade)
- Para campos menores: `md="4"` ou `md="3"`

**Seções de formulário** separadas por:
```vue
<v-divider class="my-3" />
```

---

