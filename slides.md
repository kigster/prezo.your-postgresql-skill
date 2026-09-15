<!-- .slide: class="center title-slide" -->

<div class="subtitle">15 minutes · for Ruby developers who ship with coding agents</div>

# What belongs in your<br>PostgreSQL<br><span class="hit">skills file</span><span class="cursor"></span>

<div class="date">Konstantin Gredeskoul · kig.re</div>

Note: [0:00, 30 seconds] Your coding agent writes a lot of your migrations now. This talk is about the file that tells it how. I start with the one question every other rule depends on, then walk through the file I use, rule by rule. You can copy the structure tonight.

---

<!-- .slide: data-auto-animate -->

<div class="eyebrow" data-id="step-zero">Step zero</div>

## Which database are you building?

<div class="four-grid rise">

<div class="card">

### PG-lax

A game or a social app. A lost row costs little. Speed matters more than strictness.

</div>

<div class="card">

### PG-traditional

An online store, or an app with a lot of user data. Integrity saves you support tickets.

</div>

<div class="card amber">

### PG-strict

Money, taxes, health records. A mistake costs real money, and auditors will ask.

</div>

<div class="card">

### PG-analytics

A data warehouse. Few users, long queries, batch imports, materialized views.

</div>

</div>

<p class="fragment">Your agent cannot guess this from your table names. <strong>You have to tell it.</strong></p>

Note: [0:30 to 1:30] Before any rule about indexes or keys, answer one question. What kind of database is this? I use four classes. Lax is a game or a social app, where a missing row is an annoyance. Traditional is an online store, where referential integrity saves you from customer complaints. Strict is money, taxes, and health records, where a mistake is an audit finding. Analytics is a warehouse with a few people running long queries. You probably know which one you run. Your agent does not, and it will not ask unless the file tells it to.

---

<!-- .slide: data-auto-animate -->

<div class="eyebrow" data-id="step-zero">Step zero</div>

## The answer changes the rules

<table class="class-table">
<thead>
<tr><th></th><th>PG-lax</th><th>PG-traditional</th><th class="hot">PG-strict</th><th>PG-analytics</th></tr>
</thead>
<tbody>
<tr class="fragment"><td>Deletes</td><td>Physical</td><td>Decide per table</td><td class="hot">Logical only, <code>deleted_at</code></td><td>Rare</td></tr>
<tr class="fragment"><td><code>ON DELETE</code></td><td><code>CASCADE</code></td><td>Stated on every key</td><td class="hot">Custom, sets <code>deleted_at</code></td><td>Rarely matters</td></tr>
<tr class="fragment"><td>Row locking</td><td><code>lock_version</code> is fine</td><td>Where money moves</td><td class="hot"><code>FOR UPDATE</code> by default</td><td>Few writers</td></tr>
</tbody>
</table>

<div class="fragment">

```markdown
<!-- AGENTS.md -->
Database class: PG-strict. Logical deletes only. Ask before any physical DELETE.
```

</div>

<div class="kill fragment">Skip this line and your agent adds ON DELETE CASCADE to a ledger.</div>

Note: [1:30 to 2:45] Here is why the class comes first. The same question gets four different answers. Should a delete remove the row? In a game, yes. In a ledger, never. What happens to child rows when a parent goes away? Cascade in a game, a custom soft delete in a bank. Do you lock rows before you update a balance? In a strict app, always. So the first rule in my skill says: ask the human for the class, or read it from the spec, and write it in AGENTS.md. One line. Every later decision reads it. Without that line, an agent will happily put a cascading delete on your ledger table.

---

<div class="eyebrow">Why write it down</div>

## Your agent writes code faster than you can review it

<div class="two-columns">

<div>

<div class="gap-chart">
<div class="gap-row"><span class="gap-label">Code written</span><div class="gap-bar"><div class="gap-fill"></div></div><span class="gap-num">~500x</span></div>
<div class="gap-row"><span class="gap-label">Code reviewed</span><div class="gap-bar"><div class="gap-fill flat"></div></div><span class="gap-num amber">1x</span></div>
</div>

So I moved my judgment to the place the agent reads before it writes the first line: a skill file.

<p class="fragment">When the agent adds <code>lock_timeout</code> without being asked, the file did its job.</p>

</div>

<div class="card amber">

<div class="kicker">Write your own</div>

A skill file changes the code your agent writes. Read someone else's file as carefully as a new gem with production access.

Better, write yours from incidents you lived through. You know things a downloaded file does not.

</div>

</div>

Note: [2:45 to 3:45] Why a file at all? Because review does not scale. My own output went up about five hundred times. My review time did not. The only thing that scales is taste that you wrote down, in the context the agent loads before it starts. A word of caution. Skill files are the new copy and paste from the internet. A markdown file that tells an agent how to write your migrations deserves more scrutiny than a gem, not less. Use mine for ideas. Then write your own, from the outages you remember.

---

<div class="eyebrow">How the file is built</div>

## A short trigger file, and a long reference file

<div class="three-grid rise">

<div class="card">

<div class="kicker">The YAML description</div>

### When to load

Lists the words that should load the skill: `migration`, `add_index`, `uuidv7`, `deleted_at`, `ON DELETE`.

</div>

<div class="card">

<div class="kicker">SKILL.md, about 80 lines</div>

### What never to miss

Step zero, then eight rules that fail silently. Then it tells the agent to read the reference.

</div>

<div class="card">

<div class="kicker">references/practices.md</div>

### Why, in detail

The explanations and the measurements. The agent reads it only when it designs schema.

</div>

</div>

<p class="fragment">The description says <em>when</em> to load the file. If it summarizes the rules, the agent skips the file.</p>

Note: [3:45 to 4:45] The file has three parts. The description in the YAML header decides when the agent loads the skill, so it lists trigger words. SKILL.md is short. It holds step zero and the rules whose violation passes code review and fails later in production. Everything else lives in a reference file that the agent opens only when it needs it. That keeps your context small. One trap: do not summarize the rules in the description. The agent reads the summary, decides it knows enough, and never opens the file. The next few slides are the eight rules from my SKILL.md.

---

<div class="eyebrow warning">Rule 1 · Migrations</div>

## A migration can take your site down before it runs

<div class="lock-queue">
<div class="q holder"><b>SELECT</b><small>long report, holds a lock</small></div>
<div class="q alter"><b>ALTER TABLE</b><small>waits for an exclusive lock</small></div>
<div class="q sel" style="--i:1"><b>SELECT</b><small>waits</small></div>
<div class="q sel" style="--i:2"><b>SELECT</b><small>waits</small></div>
<div class="q sel" style="--i:3"><b>SELECT</b><small>waits</small></div>
<div class="q sel" style="--i:4"><b>SELECT</b><small>waits</small></div>
<div class="q sel" style="--i:5"><b>SELECT</b><small>waits</small></div>
</div>

<div class="two-columns">

<div>

PostgreSQL grants locks in order of arrival. Every `SELECT` that arrives after your `ALTER` waits behind it.

`strong_migrations` checks the SQL. It does not check the wait.

</div>

<div>

```ruby
class AddCurrencyToInvoices < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      execute "SET lock_timeout = '3s'"
      add_column :invoices, :currency, :string
    end
  end
end
```

</div>

</div>

<p class="fragment">Give up after three seconds and retry. Build every index <code>concurrently</code>, alone in its own migration.</p>

Note: [4:45 to 6:00] Rule one. Treat a migration as a production operation. You know to build indexes concurrently. Fewer people know this one. ALTER TABLE needs an exclusive lock. If a report is reading the table, the ALTER cannot start, so it waits in the lock queue. PostgreSQL serves that queue in order, so every ordinary SELECT that arrives next waits behind your ALTER. Watch the queue grow. The migration has not changed anything yet, and the site is already down. The fix is one line: set lock_timeout to three seconds. If the lock is not free, the migration fails fast, changes nothing, and you retry. Put this line in the skill, because agents write the add_column and never the timeout.

---

<div class="eyebrow warning">Rule 2 · NOT NULL</div>

## Add NOT NULL in three migrations, not one

<div class="steps">

<div class="card fragment">
<div class="num">01</div>
<div>
<div class="kicker">Add the check, read no rows</div>
<p><code>ADD CONSTRAINT ... CHECK (currency IS NOT NULL) NOT VALID</code> takes a brief lock and scans nothing.</p>
</div>
</div>

<div class="card fragment">
<div class="num">02</div>
<div>
<div class="kicker">Validate in a separate migration</div>
<p><code>VALIDATE CONSTRAINT</code> scans the table while writes continue.</p>
</div>
</div>

<div class="card fragment">
<div class="num">03</div>
<div>
<div class="kicker">Set NOT NULL</div>
<p>PostgreSQL 12 and later use the validated check as proof and skip the scan.</p>
</div>
</div>

</div>

`change_column_null` does it in one step, and holds the strongest lock while it reads every row.

Note: [6:00 to 7:00] Rule two. Adding a column with a default is safe since PostgreSQL 11. Adding null false to an existing column is not. The agent will reach for change_column_null, which locks the whole table and scans every row to prove there are no nulls. On a big table, that is an outage. The safe version is three migrations. First, add a check constraint marked NOT VALID, which takes a brief lock and reads nothing. Second, validate it, which scans the table but lets writes continue. Third, set NOT NULL. PostgreSQL sees the validated check and skips the scan. Nobody remembers this at 11 at night, so write it down.

---

<div class="eyebrow warning">Rules 3, 5, 6, 8</div>

## Four rules that fit on one line each

<div class="four-grid rise">

<div class="card">

### schema_format = :sql

`schema.rb` silently drops partial indexes, expression indexes, exclusion constraints, generated columns, and extensions.

</div>

<div class="card">

### timestamptz

Rails still maps `t.datetime` to `timestamp`. Set `datetime_type = :timestamptz` in an initializer.

</div>

<div class="card amber">

### Foreign keys, with ON DELETE

Validations are not constraints. An unstated `ON DELETE` is a decision nobody made.

</div>

<div class="card">

### Vendor data in its own schema

Stripe tables go in `stripe.*`, Plaid tables in `plaid.*`. Never in `public`.

</div>

</div>

Note: [7:00 to 8:00] These four are short, and you probably know them. They still get a line in the skill, because the agent follows Rails defaults, and the Rails defaults are wrong here. schema.rb cannot represent a partial index, so switch to structure.sql. Rails still creates timestamp without time zone, so set the adapter's datetime type to timestamptz. Add a real foreign key on every reference, and write the ON DELETE behavior out, because the default is a choice nobody made. And when you mirror a vendor's data, such as Stripe webhooks, put it in its own schema so its table names never collide with yours.

---

<div class="eyebrow warning">Rule 4 · Primary keys</div>

## Use uuidv7 keys, and know what they reveal

<div class="two-columns">

<div>

```ruby
create_table :invoices, id: :uuid,
  default: -> { "uuidv7()" } do |t|
  t.timestamps
end
```

<div class="pages">
<div class="pages-label">uuidv4: every insert touches a random, half-empty page</div>
<div class="page-row v4">
<i style="--d:3"></i><i style="--d:11"></i><i style="--d:6"></i><i style="--d:0"></i><i style="--d:14"></i><i style="--d:8"></i><i style="--d:2"></i><i style="--d:12"></i><i style="--d:5"></i><i style="--d:9"></i><i style="--d:1"></i><i style="--d:15"></i><i style="--d:7"></i><i style="--d:13"></i><i style="--d:4"></i><i style="--d:10"></i>
</div>
<div class="pages-label">uuidv7: inserts fill full pages at the end</div>
<div class="page-row v7">
<i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i class="tail"></i>
</div>
</div>

</div>

<div class="card amber">

<div class="kicker">The tradeoff</div>

A uuidv7 shows when its row was created. With enough IDs from your URLs, anyone can estimate how fast you grow.

If that matters, show a uuidv4 outside and keep the uuidv7 inside.

The extra 8 bytes over `bigint` do not matter. The insert speed does.

</div>

</div>

Note: [8:00 to 9:00] Rule four. A primary key carries no business meaning and is never composite. PostgreSQL 18 ships uuidv7 built in. Here is why it matters. A version 4 UUID is random, so every insert goes to a random page of the index. Once the index is bigger than memory, each insert reads a page from disk, and pages split half empty. That is the top row. Version 7 puts the time first, so inserts go to the end of the index, the way a bigserial does. That is the bottom row. The gap is often ten times on large tables. The cost: the ID reveals when the row was created. The skill has to name that tradeoff, or the agent will never mention it.

---

<div class="eyebrow warning">Rule 7 · Soft deletes</div>

## Soft deletes need partial indexes. The index has a cost.

<div class="two-columns">

<div>

In a PG-strict app, nearly every query says `WHERE deleted_at IS NULL`. A partial index covers only live rows, so it stays small.

A soft delete is still an `UPDATE`. It leaves a dead row version for vacuum.

A HOT update skips the index writes. It works only when the update changes no indexed column, and the partial index's `WHERE` counts.

</div>

<div class="card amber">

<div class="kicker">HOT updates out of 200 soft deletes, PostgreSQL 18</div>

<div class="hot-bars">
<div class="hot-row"><span class="hot-label">No index on <code>deleted_at</code></span><div class="hot-bar"><div class="hot-fill" style="--w:87%"></div></div><span class="hot-num">174</span></div>
<div class="hot-row"><span class="hot-label"><code>WHERE deleted_at IS NULL</code></span><div class="hot-bar"><div class="hot-fill" style="--w:0%"></div></div><span class="hot-num amber">0</span></div>
</div>

Both runs left 200 dead tuples. Keep the partial index on PG-strict. The reads matter more.

</div>

</div>

Note: [9:00 to 10:15] Rule seven, and the one that surprised me. If you soft delete, put WHERE deleted_at IS NULL on nearly every index. The index covers only live rows, so it stays small and fast. But know the cost. A soft delete is an UPDATE, and every UPDATE leaves a dead row version for vacuum. A heap-only tuple update, HOT for short, avoids the index writes, but only if you changed no indexed column. The partial index predicate counts as indexed. I measured it on PostgreSQL 18: 174 HOT updates out of 200 without the partial index, zero with it. For a strict app, keep the index anyway. The skill states the tradeoff so the agent does not drop the index to chase HOT.

---

<div class="eyebrow warning">Indexes</div>

## Order index columns: equality, then range, then sort

<div class="two-columns">

<div>

```sql
WHERE account_id = ?
ORDER BY created_at DESC
LIMIT 20
```

<p class="fragment"><span class="chip">serves it</span> <code>(account_id, created_at)</code></p>

<p class="fragment"><span class="chip amber">useless</span> <code>(created_at, account_id)</code></p>

<p class="fragment">Selectivity only breaks a tie. The shape of the query decides.</p>

</div>

<div class="card amber">

<div class="kicker">Rails leaves an extra index behind</div>

`add_reference` creates an index on `(account_id)`.

Three sprints later, someone adds `(account_id, created_at)`. Now the first index is redundant, and nobody drops it.

Find the ones nobody uses: `pg_stat_user_indexes` where `idx_scan = 0`.

</div>

</div>

Note: [10:15 to 11:15] This is the one index rule worth carrying in your head. Put equality columns first, then range columns, then the sort column. The index on account ID and created at serves the query on the left. Reverse the columns and it serves nothing. You may have been taught to put the most selective column first. That only breaks a tie. And here is where Rails apps get heavy: belongs to creates a single-column index, and later someone adds the composite. The composite answers everything the single index did, so the single one is dead weight. Query pg_stat_user_indexes for indexes with zero scans. That is your list to drop.

---

<div class="eyebrow">The reference file</div>

## Everything else goes in the reference file

<div class="three-grid rise">

<div class="card">

### Locking

`READ COMMITTED` gives each statement a new snapshot. Use `FOR UPDATE` for read-then-write.

</div>

<div class="card">

### Money

`bigint` cents plus a `char(3)` currency. Never `float`.

</div>

<div class="card">

### Timeouts

`statement_timeout` per role: 30 seconds for web, longer for jobs.

</div>

<div class="card">

### Pooling

pgBouncer in transaction mode. About 16 to 20 server connections on 8 cores.

</div>

<div class="card">

### STI types

Store `banana` in `type`, not `Fruit::Banana`. A module rename then costs nothing.

</div>

<div class="card amber">

### Wraparound

An open snapshot blocks freezing. Turning autovacuum off does not.

</div>

</div>

Note: [11:15 to 12:30] SKILL.md stays short on purpose. The rest lives in the reference file, which the agent reads before it designs a schema. A few examples. Two SELECTs in one transaction can disagree, so read-modify-write needs FOR UPDATE. Money is integer cents with a currency code. Timeouts are set on the database role, so connection pooling cannot drop them. The pool on the database side is small, around twenty connections for eight cores. Store a short lowercase token in STI type columns so a module rename is not a data migration. And transaction ID wraparound comes from a snapshot someone left open, not from autovacuum being off. The whole file is in the blog post.

---

<div class="eyebrow">Your turn</div>

## Write your own file this week

<ol class="benefits-list">
<li class="fragment">Classify your database. Write the class in AGENTS.md.</li>
<li class="fragment">Write a description that lists the words that should load the file.</li>
<li class="fragment">Put the rules that fail silently in SKILL.md. Keep it under 100 lines.</li>
<li class="fragment">Move the explanations and measurements to a reference file.</li>
<li class="fragment">Add a rule each time an incident teaches you one.</li>
</ol>

<div class="kill fragment">Then run the unused-index query on production. I dare you.</div>

Note: [12:30 to 13:30] Here is the recipe. Start with the class, because every rule depends on it. Write a description that triggers on the words you actually type. Keep SKILL.md short, and fill it with the rules whose failure is silent: the lock timeout, the three-step NOT NULL, the partial index tradeoff. Put the long explanations in a reference file. Then keep it alive. Each outage you survive is a line in the file. If a new PostgreSQL release contradicts a rule, the file tells the agent to stop and ask you. And yes, run the unused-index query. You will find something.

---

<!-- .slide: class="center final-slide" -->

# Thanks

<div class="author-section">
  <div class="questions">
    What did I get wrong?<br>
    What did you measure?<br>
    What is in your file?
  </div>
  <img src="assets/img/kig.jpeg" alt="Konstantin Gredeskoul" class="author-photo">
</div>

<div class="author-credit"><a href="https://kig.re/2026/08/19/condensing-twenty-years-of-wisdom-in-one-markdown.html">kig.re · Condensing twenty years of wisdom in one markdown</a></div>

Note: [13:30 to 15:00] The whole file is in that post. Take it, argue with it, and write your own. I would like to hear the arguments, especially if you measured a HOT number different from 174.
