-- Tables carry the module's own prefix; core_ tables may be referenced and are
-- never altered. A change to a published table is a migration in
-- apps/api/register.ts, never an edit here: this file runs only where the
-- table does not exist yet.

-- One row per account: how often it said hello.
CREATE TABLE IF NOT EXISTS demo_hello_world_greetings (
  account_id TEXT PRIMARY KEY REFERENCES core_accounts(id) ON DELETE CASCADE,
  count INTEGER NOT NULL DEFAULT 0
);

-- One row per note.
CREATE TABLE IF NOT EXISTS demo_hello_world_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id TEXT NOT NULL REFERENCES core_accounts(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_demo_hello_world_notes_account ON demo_hello_world_notes(account_id, id);
