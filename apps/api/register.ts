// The code half of this module's registration. Called once at boot by the
// generated registration, after core's own.
//
// The type import below is erased at build time; its relative path only has to
// resolve for an editor, with the module unpacked at modules/demo/greeter in a
// core checkout.
import type { LibsqlDb } from '../../../../core/api/server/utils/data/libsql-client'

/** Guarded changes to this module's OWN tables. They run on every boot, so each
 *  one checks before it acts and is a no-op the second time. */
export const migrations = [
  async (db: LibsqlDb) => {
    const cols = await db.pragma('table_info(demo_greeter_counts)') as Array<{ name: string }>
    if (!cols.some(c => c.name === 'last_at')) {
      await db.exec('ALTER TABLE demo_greeter_counts ADD COLUMN last_at TEXT')
    }
  }
]

/** `api` is the only way a module reaches core's registries; it puts
 *  the module's id in front of every name, so this task is `demo.greeter:tick`. */
export function register(api: { cronTask: (name: string, task: unknown) => void }): void {
  api.cronTask('tick', {
    label: 'Greeter tick',
    description: 'Demo module task: reports how many accounts have been greeted.',
    requiresOs: false,
    run: async () => {
      const db = await getDb()
      const row = await db.prepare('SELECT COUNT(*) AS n FROM demo_greeter_counts').get() as { n: number }
      return `greeted accounts: ${row.n}`
    }
  })
}
