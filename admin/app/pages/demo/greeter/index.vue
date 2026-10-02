<script setup lang="ts">
const api = useApiClient()
const hello = ref<{ message: string, count: number } | null>(null)

async function greet() {
  hello.value = await api<{ message: string, count: number }>('/api/demo/greeter/hello')
}

onMounted(greet)
</script>

<template>
  <div class="p-6 max-w-xl space-y-4" data-module="demo.greeter">
    <h1 class="text-xl font-semibold">Greeter</h1>
    <p v-if="hello">{{ hello.message }}. Greeted {{ hello.count }} time(s).</p>
    <UButton @click="greet">Greet again</UButton>
  </div>
</template>
