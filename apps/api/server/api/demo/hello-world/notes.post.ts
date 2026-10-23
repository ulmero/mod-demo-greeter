import { addNote, listNotes } from '../../../lib/hello-world'

export default defineFeatureHandler('demo.hello-world', async (_feat, event) => {
  const scope = requireAccess(event, 'Demo.HelloWorld')
  if (!scope) throw createError({ statusCode: 401, message: 'Authentication required' })
  const body = await readBody<{ body?: unknown }>(event)
  const text = typeof body?.body === 'string' ? body.body.trim() : ''
  if (!text) throw createError({ statusCode: 400, message: 'A note needs some text' })
  await addNote(scope.accountId, text)
  return { notes: await listNotes(scope.accountId) }
})
