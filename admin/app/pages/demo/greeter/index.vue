<script setup lang="ts">
const { t } = useI18n()
const api = useApiClient()
const hello = ref<{ message: string, count: number } | null>(null)

async function greet() {
  hello.value = await api<{ message: string, count: number }>('/api/demo/greeter/hello')
}

onMounted(greet)
</script>

<template>
  <div class="p-6 max-w-xl space-y-4" data-module="demo.greeter">
    <h1 class="text-xl font-semibold">{{ t('demo.greeter.title') }}</h1>
    <p v-if="hello">{{ t('demo.greeter.greeted', hello.count) }}</p>
    <UButton @click="greet">{{ t('demo.greeter.greetAgain') }}</UButton>
  </div>
</template>
