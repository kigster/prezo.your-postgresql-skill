<!-- .slide: class="center title-slide" -->

<div class="subtitle">15 min · Rails seniors · you already know concurrent indexes</div>

# What belongs in your<br>PostgreSQL<br><span class="hit">skills file.</span>

<div class="date">kig.re · twenty years in one markdown</div>

Note: The file is public. August 2026, kig.re. Concurrent indexes, foreign keys, timestamptz. You have heard those. They still get a line in SKILL.md because agents have not. This talk is the other half, and the reason the file exists at all.

---

<div class="eyebrow">Why the file exists</div>

## If you cannot review the output, constrain the input.

<div class="four-grid">

<div class="card">

<div class="kicker">500x THE CODE</div>

Working code. My rules. Tests on top. The review bandwidth of a human did not go up 500x. It went up 0x.

</div>

<div class="card">

<div class="kicker">TASTE, UPSTREAM</div>

Move judgment out of the diff and into the context the agent reads before it writes a line.

</div>

<div class="card amber">

<div class="kicker">DO NOT CURL PIPE BASH</div>

A markdown file that reprograms the thing writing your code deserves more scrutiny than a transitive npm dep. Write your own.

</div>

<div class="card amber">

<div class="kicker">TONIGHT</div>

FIFO locks. HOT vs partials. Wraparound folklore. STI FKs that lie. Classify first.

</div>

</div>

Note: This is the post. I have become the single-threaded process in an embarrassingly parallel system. The only leverage that scales is taste, written down. When the agent reaches for concurrently and lock_timeout and amount_cents without being asked, that is not the model being clever. That is me being complimented by my own reflection. Still counts. The rest of the slides are the rules I had to write because the model has the blog post and not the measurement.

---

<div class="eyebrow">File layout</div>

## Thin trigger. Fat reference. The weird stuff in both.

<div class="three-grid">

<div class="card">

<div class="kicker">TRIPWIRE</div>

### SKILL.md

When to load. Classify first. The rules that fail silently. Then stop.

</div>

<div class="card">

<div class="kicker">THE BODY</div>

### practices.md

HOT, FIFO, uuidv7 locality, STI, money, pooling. Read it before writing schema.

</div>

<div class="card">

<div class="kicker">FOLKLORE</div>

### autovacuum.md

Wraparound is not what you were told. Read it before you touch a knob.

</div>

</div>

The YAML description is when to open the file. Summarize the workflow there and the agent will never open the file.

Note: Same shape as before. SKILL.md is a tripwire, not a blog post. The unusual rules have to be named in SKILL.md, because those are the ones an agent will skip under time pressure. The measurements and the folklore live in references. Lazy load. Do not dump four hundred lines into every chat.

---

<div class="eyebrow">Step zero. Not optional.</div>

## Classify the database. Write it in AGENTS.md.

<div class="four-grid">

<div class="card">

### PG-lax

Games, social. Physical deletes. ON DELETE CASCADE. Speed over strictness.

</div>

<div class="card">

### PG-traditional

E-commerce, PII. Integrity matters. Delete strategy is a production decision.

</div>

<div class="card amber">

### PG-strict

Money, taxes, health. Logical deletes only. Immutability. Audit trails.

</div>

<div class="card">

### PG-analytics

Warehouse. Materialized views. Batch ingest. Rare deletes. Long queries.

</div>

</div>

<div class="kill">Skip this and the agent CASCADES a ledger.</div>

Note: This is the one page the rest of the file is illegal without. Soft deletes, ON DELETE, whether FOR UPDATE is ceremony or the baseline, even whether money rules apply. Ask, or read it from the spec. Record it in AGENTS.md. Do not infer it from the table names and keep going. An agent that skips classification will apply PG-strict to a game, or CASCADE to a ledger. Seniors think they already classified it. They have not written it down, so the agent has not either.

---

<div class="eyebrow warning">The wait, not the statement</div>

## The migration never ran. The site is down.

<div class="two-columns">

<div>

strong_migrations catches dangerous SQL. It does not catch the queue.

ALTER TABLE needs ACCESS EXCLUSIVE. If anything is reading the table, the ALTER waits.

Lock requests are FIFO. Every SELECT that arrives after you queued, queues behind you.

<div class="kill">You changed nothing. You still took production down.</div>

</div>

<div>

```ruby
execute "SET lock_timeout = '3s'"
add_column :invoices, :currency, :string
```

Fail in three seconds. Retry. A failed attempt that changed nothing costs you nothing.

</div>

</div>

Note: Seniors know ACCESS EXCLUSIVE is a big lock. They do not know the outage is usually the wait. The ALTER has not started. It is sitting in the lock queue. Everything behind it is ACCESS SHARE, which cannot jump the line, because Postgres lock queues are FIFO. Set lock_timeout. Three seconds on a hot table. Fail fast. Retry in a loop. This has to be in the skill because every agent will write the add_column and none of them will set the timeout.

---

<div class="eyebrow warning">NOT NULL without a rewrite</div>

## CHECK NOT VALID scans nothing. Then you prove it.

A column default is safe on PG 11+. Adding null: false to an existing column is not. Three migrations.

<div class="steps">

<div class="card">
<div class="num">01</div>
<div>
<div class="kicker">NOT VALID</div>
<p>CHECK (currency IS NOT NULL) NOT VALID. ACCESS EXCLUSIVE. Scans nothing.</p>
</div>
</div>

<div class="card">
<div class="num">02</div>
<div>
<div class="kicker">VALIDATE</div>
<p>VALIDATE CONSTRAINT, own migration. Shares the table. Scans. Does not block writes.</p>
</div>
</div>

<div class="card">
<div class="num">03</div>
<div>
<div class="kicker">SET NOT NULL</div>
<p>PG 12+ treats the validated CHECK as proof and skips the table rewrite.</p>
</div>
</div>

</div>

Note: The agent will reach for change_column_null. That rewrites the table. The dance is CHECK NOT VALID, which takes the lock and does no scan, then VALIDATE in a second migration, which scans while writes continue, then SET NOT NULL. Postgres 12 and later looks at the validated constraint and does not rewrite. Put the three steps in the skill. Nobody remembers this at 11pm.

---

<div class="eyebrow warning">HOT vs the partial you were told to add</div>

## Soft delete is still an UPDATE. It still makes dead tuples.

<div class="two-columns">

<div>

A logical delete does not skip vacuum. MVCC writes a new row version. A million deleted_at stamps is a million dead tuples.

What actually helps is a HOT update. The new version stays on the same page. Indexes are not touched. Only if you did not index the column you changed.

<div class="kill">The partial index you wanted is the thing that kills HOT.</div>

</div>

<div class="card amber">

<div class="kicker">PG 18. 200 SOFT DELETES.</div>

<div class="stat">174</div>
HOT. deleted_at in no index at all.

<div class="stat amber">zero</div>
HOT. With WHERE deleted_at IS NULL.

200 dead tuples either way. Keep the partial on PG-strict. Know the tax.

</div>

</div>

Note: This is the one that is backwards from intuition. HOT eligibility considers every column any index references, including a partial index predicate. Setting deleted_at from NULL to a timestamp changes the predicate, so the row must leave that index, so the update is not HOT. Measured on 18, with page headroom: 174 HOT without the partial, zero with it. Both still 200 dead tuples. For PG-strict you still want the partial. The read path dominates. The skill has to say the tradeoff, or the agent will skip the index to chase HOT, or add it and think vacuum went away.

---

<div class="eyebrow warning">Selectivity is a tiebreaker</div>

## Equality, then range, then sort. In that order.

<div class="two-columns">

<div>

(account_id, created_at) serves WHERE account_id = ? ORDER BY created_at DESC LIMIT 20.

(created_at, account_id) serves it not at all.

Most selective column first is the rule you were taught. It is the wrong rule.

</div>

<div class="card amber">

<div class="kicker">RAILS MADE YOU FAT</div>

add_reference already created (account_id).

Three sprints later you add (account_id, created_at).

Leftmost prefix. The first index is redundant. You never drop it.

(account_id, created_at) and (account_id, status) are not redundant. Bitmap-AND, or a partial WHERE status = pending.

</div>

</div>

Note: Access-pattern shape wins. Equality columns, then range, then the sort. Selectivity is what you use when two shapes are equal. Rails is why the catalog is fat: belongs_to auto-indexes the FK, then someone adds the composite and both live forever. pg_stat_user_indexes where idx_scan is 0 is the kill list. Put the order, and the leftover-index, in the skill. The agent will otherwise add both.

---

<div class="eyebrow warning">v4 is a random leaf. v7 is not free.</div>

## uuidv7 restores the right-hand insert. It also leaks created_at.

<div class="two-columns">

<div>

```ruby
create_table :boomerangs, id: :uuid,
  default: -> { "uuidv7()" } do |t|
  t.timestamps
end
```

No extension since PG 13. PG 18 adds uuidv7(), with a 12-bit sub-millisecond fraction, monotonic inside one backend.

v4 on a table bigger than shared_buffers is a page fault per insert. Pages split at fifty percent fill. The working set is the whole index.

</div>

<div class="card amber">

<div class="kicker">THE TRADEOFF THAT ACTUALLY MATTERS</div>

The 8 extra bytes versus bigint are noise. The insert gap between v4 and v7 is routinely an order of magnitude.

v7 puts a timestamp in the ID. Anyone holding a URL knows when the row was born, and with enough IDs, your creation rate.

If that timing is sensitive: v4 outside, v7 inside.

varchar(36) is 37 bytes plus alignment. No.

</div>

</div>

Note: Do not spend this slide on "UUIDs hide your user count." Spend it on locality. v4 is uniform random, so every insert is a random B-tree leaf. v7 puts time in front and you get right-hand splits again, ninety percent fill, a hot tail that stays in cache. Postgres 18's uuidv7 stuffs a 12-bit sub-ms fraction after the millisecond, so it is monotonic in one backend, not merely ordered. The skill has to name the leak. Agents will reach for v7 as the default, which is correct for most apps, and they will not mention the disclosure unless you write it down.

---

<div class="eyebrow warning">Bonus track. For you, not the agent.</div>

## Turning autovacuum off does not cause wraparound.

<div class="two-columns">

<div>

XID is unsigned 32-bit, cluster-wide. One counter. Not per table. Per table is only the age, relfrozenxid.

There is no free list. The counter marches. Freeze means "visible to everyone, stop asking." Since 9.4 that is a hint bit, not a magic xmin.

Anti-wraparound vacuum still launches at 200 million even if autovacuum is disabled. The manual says so.

</div>

<div class="card amber">

<div class="kicker">WHAT ACTUALLY PINS THE HORIZON</div>

idle in transaction in psql.

A reporting query that never ends.

An orphaned replication slot.

A prepared xact nobody finished.

<div class="kill">It does not enter single-user mode. Connect normally. Kill the snapshot. VACUUM.</div>

</div>

</div>

Note: In the post this was the part I did not put in the skills file, because the machines already know it and you might not. That asymmetry should worry you slightly. The folk story is you turned autovacuum off and XIDs wrapped. Wrong. Postgres will force an anti-wraparound vacuum whether autovacuum is on or not. What stops freeze is an open snapshot. Escalation: 200 million forced vacuum, 40 million remaining a WARNING, 3 million remaining it refuses new XIDs. Reads still work. The docs warn you not to restart into single-user mode. Connect, find idle-in-transaction, drop the dead slot, VACUUM. If the table is 27 terabytes that vacuum still takes days. The dashboard query is age(relfrozenxid), not autovacuum settings.

---

<div class="eyebrow warning">READ COMMITTED is weaker than it sounds</div>

## Two SELECTs in one transaction can disagree.

Each statement gets a fresh snapshot. Read the balance, compute, write it back: lost update, race as wide as your latency.

<div class="three-grid">

<div class="card">

### FOR UPDATE

Take the row as you read it. Rails: record.lock! This is the answer almost always.

</div>

<div class="card amber">

### SERIALIZABLE

Genuinely correct. Fails at COMMIT. No retry loop means you moved the bug into an error class.

</div>

<div class="card">

### lock_version

Fine for a human clicking Save. Wrong for two jobs fighting a row. Retry storm.

</div>

</div>

Deadlocks are ordering. Always lock by ascending PK, parent before child. Session advisory locks and transaction pooling cannot share a room.

Note: Seniors say we use transactions. They do not say READ COMMITTED is per statement. SERIALIZABLE in Postgres is real SSI, and it is useless without a retry loop on serialization failure. Optimistic locking is Rails default and it is the wrong tool under machine contention. Advisory locks: use the transaction-scoped variant, because session-scoped locks leak on process death and they are incompatible with pgBouncer transaction mode. Put FOR UPDATE as the default in the skill for PG-strict. Put the retry loop next to SERIALIZABLE so the agent cannot take the isolation level and skip the loop.

---

<div class="eyebrow warning">The FK that does not mean what you think</div>

## Postgres will accept the FK. It will not accept the subclass.

<div class="two-columns">

<div>

A polymorphic pair can never be a real foreign key. One FK targets one table. edible_id points at whichever table edible_type named. There is no SQL for that. Delegated types exist because of this.

STI is the opposite lie. One real table, one real PK. Other tables can FK onto carts.id. Postgres will let smoothies.banana_id point at a strawberry row. If that distinction matters, CHECK or a partial unique. Not a foreign key.

</div>

<div class="card amber">

<div class="kicker">STORE BANANA. NOT Banana::Heirloom.</div>

Fully qualified class names in type are a multi-day data migration the day you rename a module.

find_sti_class. polymorphic_name. One lowercase token.

Index (edible_id, edible_type DESC) so like sits next to like.

</div>

</div>

Note: This is the Rails-shaped landmine seniors still ship. They add a FK to the STI table and think the subclass is constrained. It is not. They store Shloopify::Checkout::Cart in type, then the company gets bought, and now you are rewriting millions of rows. One word tokens. Delegated types when you actually need a real FK per concrete table. The skill has to forbid class names in type columns, because that is the default Rails will write.

---

<div class="eyebrow warning">Three timeouts. Three different deaths.</div>

## They are not interchangeable. Put all three in the skill.

<div class="three-grid">

<div class="card amber">

### lock_timeout

The ALTER is waiting. The world is queuing behind it. Three seconds. Fail. Retry.

</div>

<div class="card">

### statement_timeout

Per role, not per connection. app_web 30s. Jobs 10 minutes. Readonly 5. A 60 second web query is already a corpse holding a snapshot.

</div>

<div class="card amber">

### idle_in_transaction_session_timeout

The psql session somebody left inside BEGIN. It blocks vacuum. It holds locks until the laptop sleeps. This is also how you pin wraparound.

</div>

</div>

ALTER ROLE, not SET in the boot path. Transaction pooling will drop your SET.

Note: Seniors set statement_timeout in database.yml and think they are done. lock_timeout is the migration. statement_timeout is the runaway SELECT that pins xmin. idle_in_transaction_session_timeout is the human. idle_session_timeout is extra for pooled roles. Set them on the role so nobody can forget, and so pgBouncer transaction mode does not throw away a session SET. The skill should show the three ALTER ROLE lines. Agents love a single timeout. That is not enough.

---

<div class="eyebrow warning">Good intentions</div>

## Unicorn hit the memory ceiling. Then it took the database with it.

<div class="two-columns">

<div>

Worker killer. OOM. Recycle the fat process before the box swaps. Sensible.

They all hit the limit together. Master respawns them together.

Each boot is Rails init: schema cache, type map, schema_migrations, a pool of connections, all against the primary.

</div>

<div class="card amber">

<div class="kicker">THE STAMPEDE</div>

N workers times pool size. Catalog queries. pg_attribute. Health checks fail. More restarts.

<div class="kill">You protected the app box. You hammered Postgres. The site went down.</div>

</div>

</div>

Jitter the recycle. Preload. Do not let boot open a full pool. The skill has to say this, because "restart it" looks like operations, not schema.

Note: This is the one that looks like a sysadmin story until you watch pg_stat_activity. unicorn-worker-killer, or the Linux OOM killer, or a memory ceiling in the unit file. Good intentions. The workers leak, you cap them, they die, Unicorn master forks new ones. Rails initialization is not free. It talks to Postgres. A lot. Schema cache. Column types. Sometimes a SELECT from schema_migrations. And ActiveRecord opens the pool, not one connection, the pool. Twenty workers coming up at once is a hundred backends and a catalog storm on a primary that was already unhappy, which is why the workers were fat in the first place. Health check fails, more processes, more boots. The site is down and the dashboard says CPU on the database, not OOM on the app. Stagger the killer with jitter so they do not share a birthday. preload_app so boot is once. Checkout one connection at boot, not pool_size. pgBouncer so the stampede queues in the pooler, not in Postgres. Put it in the skill under pooling, or the agent will never connect a worker restart to a database outage.

---

<div class="eyebrow">Copy this outline</div>

## Steal the weird half. The hits are one-liners.

Classify first. PG-lax, traditional, strict, analytics. Write it down.

<ol class="benefits-list">
<li>lock_timeout. FIFO. The wait is the outage.</li>
<li>CHECK NOT VALID, VALIDATE, then SET NOT NULL.</li>
<li>HOT vs WHERE deleted_at IS NULL. 174 and zero. Keep the partial anyway.</li>
<li>Equality, range, sort. Drop the leftover add_reference index.</li>
<li>uuidv7 for locality. Name the created-at leak.</li>
<li>Wraparound: kill the snapshot. Do not restart into single-user.</li>
<li>READ COMMITTED is per statement. SERIALIZABLE needs a retry loop.</li>
<li>STI FKs do not constrain type. Store banana. Timeouts on the role.</li>
</ol>

Note: That is the skill. The greatest hits still get a line each so the agent does not skip concurrently, FKs, timestamptz, schema.sql. The body of the file is the measurements and the folklore. If a new Postgres release contradicts a line, stop and talk to the human. The skill is not a substitute for that conversation.

---

<!-- .slide: class="center final-slide" -->

# Thanks.

<div class="author-section">
  <div class="questions">
    What did I get wrong.<br>
    What did you measure.<br>
    What folklore still walks.
  </div>
  <img src="assets/img/kig.jpeg" alt="Konstantin Gredeskoul" class="author-photo">
</div>

<div class="author-credit"><a href="https://kig.re/2026/08/19/condensing-twenty-years-of-wisdom-in-one-markdown.html">kig.re/2026/08/19 · twenty years in one markdown</a></div>

Note: The whole file is in that post, warts and empty headings included. Take it. Argue with it. Write your own. If we have a minute I want the arguments, especially if you have a HOT number that is not 174.
