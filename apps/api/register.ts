// The code half of this module's registration. Called once at boot by the
// generated registration, after core's own.
//
// The type import below is erased at build time; its relative path only has to
// resolve for an editor, with the module unpacked at modules/demo/hello-world in
// a core checkout.
import type { LibsqlDb } from '../../../../../core/api/server/utils/data/libsql-client'

/** Guarded changes to this module's OWN tables. They run on every boot, so each
 *  one checks before it acts and is a no-op the second time. This one adds the
 *  time of the last hello to a table that schema.sql created without it. */
export const migrations = [
  async (db: LibsqlDb) => {
    const cols = await db.pragma('table_info(demo_hello_world_greetings)') as Array<{ name: string }>
    if (!cols.some(c => c.name === 'last_at')) {
      await db.exec('ALTER TABLE demo_hello_world_greetings ADD COLUMN last_at TEXT')
    }
  }
]

/** `api` is the only way a module reaches core's registries; it puts
 *  the module's id in front of every name, so this task is `demo.hello-world:tick`. */
export function register(api: { cronTask: (name: string, task: unknown) => void }): void {
  api.cronTask('tick', {
    label: 'Hello world tick',
    description: 'Demo module task: reports how many accounts said hello and how many notes exist.',
    requiresOs: false,
    run: async () => {
      const db = await getDb()
      const greeted = await db.prepare('SELECT COUNT(*) AS n FROM demo_hello_world_greetings').get() as { n: number }
      const notes = await db.prepare('SELECT COUNT(*) AS n FROM demo_hello_world_notes').get() as { n: number }
      return `accounts that said hello: ${greeted.n}, notes: ${notes.n}`
    }
  })
}
