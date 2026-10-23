// The module's queries, shared by its routes. Files under server/lib are not
// routes: the routes import them by relative path.
//
// left-pad is a package core does not ship: it proves a module's own
// dependency (module.json "dependencies") is installed for it and bundled into
// the build.
import leftPad from 'left-pad'

export interface Greetings { count: number, lastAt: string | null }
export interface Note { id: number, ref: string, body: string, createdAt: string }

/** The longest note the API stores. Longer text is cut to this length. */
export const NOTE_MAX = 2000

export async function readGreetings(accountId: string): Promise<Greetings> {
  const db = await getDb()
  const row = await db.prepare(
    'SELECT count, last_at FROM demo_hello_world_greetings WHERE account_id = ?'
  ).get(accountId) as { count: number, last_at: string | null } | undefined
  return { count: row?.count ?? 0, lastAt: row?.last_at ?? null }
}

export async function sayHello(accountId: string): Promise<Greetings> {
  const db = await getDb()
  await db.prepare(
    `INSERT INTO demo_hello_world_greetings (account_id, count, last_at) VALUES (?, 1, ?)
     ON CONFLICT(account_id) DO UPDATE SET count = count + 1, last_at = excluded.last_at`
  ).run(accountId, new Date().toISOString())
  return readGreetings(accountId)
}

export async function listNotes(accountId: string): Promise<Note[]> {
  const db = await getDb()
  const rows = await db.prepare(
    'SELECT id, body, created_at FROM demo_hello_world_notes WHERE account_id = ? ORDER BY id DESC LIMIT 200'
  ).all(accountId) as Array<{ id: number, body: string, created_at: string }>
  return rows.map(r => ({ id: r.id, ref: `N-${leftPad(String(r.id), 5, '0')}`, body: r.body, createdAt: r.created_at }))
}

export async function addNote(accountId: string, body: string): Promise<void> {
  const db = await getDb()
  await db.prepare(
    'INSERT INTO demo_hello_world_notes (account_id, body, created_at) VALUES (?, ?, ?)'
  ).run(accountId, body.slice(0, NOTE_MAX), new Date().toISOString())
}
