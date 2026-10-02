export default defineFeatureHandler('demo.greeter', async (_feat, event) => {
  const scope = requireAccess(event, 'Demo.Greeter')
  if (!scope) throw createError({ statusCode: 401, message: 'Authentication required' })
  const db = await getDb()
  await db.prepare(
    `INSERT INTO demo_greeter_counts (account_id, count, last_at) VALUES (?, 1, ?)
     ON CONFLICT(account_id) DO UPDATE SET count = count + 1, last_at = excluded.last_at`
  ).run(scope.accountId, new Date().toISOString())
  const row = await db.prepare('SELECT count, last_at FROM demo_greeter_counts WHERE account_id = ?').get(scope.accountId) as { count: number, last_at: string }
  return { message: 'Hello from the greeter module', count: row.count, lastAt: row.last_at }
})
