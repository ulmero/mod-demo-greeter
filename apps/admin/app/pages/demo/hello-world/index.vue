<script setup lang="ts">
// Demo module page: say hello (the count and a dialog), and keep notes.
interface Greetings { count: number, lastAt: string | null }
interface Note { id: number, ref: string, body: string, createdAt: string }

const { t } = useI18n()
const api = useApiClient()
const toast = useAppToast()

const greetings = ref<Greetings | null>(null)
const helloOpen = ref(false)
const greeting = ref(false)

const notes = ref<Note[]>([])
const draft = ref('')
const adding = ref(false)

async function load() {
  const [g, n] = await Promise.all([
    api<Greetings>('/api/demo/hello-world/hello'),
    api<{ notes: Note[] }>('/api/demo/hello-world/notes')
  ])
  greetings.value = g
  notes.value = n.notes
}

async function sayHello() {
  greeting.value = true
  try {
    greetings.value = await api<Greetings>('/api/demo/hello-world/hello', { method: 'POST' })
    helloOpen.value = true
  } catch (e) {
    toast.error(e, t('demo.helloWorld.helloFailed'))
  } finally {
    greeting.value = false
  }
}

async function addNote() {
  if (!draft.value.trim()) return
  adding.value = true
  try {
    notes.value = (await api<{ notes: Note[] }>('/api/demo/hello-world/notes', { method: 'POST', body: { body: draft.value } })).notes
    draft.value = ''
  } catch (e) {
    toast.error(e, t('demo.helloWorld.addFailed'))
  } finally {
    adding.value = false
  }
}

onMounted(load)
</script>

<template>
  <AppPage :title="t('demo.helloWorld.title')">
    <div class="max-w-2xl space-y-6" data-module="demo.hello-world">
      <UCard>
        <template #header>
          <h2 class="font-semibold">{{ t('demo.helloWorld.helloHeading') }}</h2>
        </template>
        <div class="flex items-center justify-between gap-4">
          <p v-if="greetings">{{ t('demo.helloWorld.count', greetings.count) }}</p>
          <UButton icon="i-lucide-hand" :loading="greeting" @click="sayHello">
            {{ greetings?.count ? t('demo.helloWorld.sayHelloAgain') : t('demo.helloWorld.sayHello') }}
          </UButton>
        </div>
      </UCard>

      <UCard>
        <template #header>
          <h2 class="font-semibold">{{ t('demo.helloWorld.notesHeading') }}</h2>
        </template>
        <div class="space-y-4">
          <form class="flex gap-2" @submit.prevent="addNote">
            <UInput v-model="draft" class="flex-1" :placeholder="t('demo.helloWorld.placeholder')" :aria-label="t('demo.helloWorld.placeholder')" />
            <UButton type="submit" icon="i-lucide-plus" :loading="adding" :disabled="!draft.trim()">
              {{ t('demo.helloWorld.add') }}
            </UButton>
          </form>
          <EmptyState v-if="!notes.length" :message="t('demo.helloWorld.noNotes')" :bordered="false" />
          <ul v-else class="space-y-2">
            <li v-for="n in notes" :key="n.id" class="rounded border border-default p-3">
              <p>{{ n.body }}</p>
              <p class="text-xs text-muted">{{ n.ref }} · {{ new Date(n.createdAt).toLocaleString() }}</p>
            </li>
          </ul>
        </div>
      </UCard>
    </div>

    <UModal v-model:open="helloOpen" :title="t('demo.helloWorld.helloWorld')">
      <template #body>
        <p v-if="greetings">{{ t('demo.helloWorld.count', greetings.count) }}</p>
      </template>
    </UModal>
  </AppPage>
</template>
