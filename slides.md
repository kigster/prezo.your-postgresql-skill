<!-- .slide: class="center title-slide" -->

<div class="subtitle">A 15-minute talk for Ruby developers who ship with coding agents</div>

# What belongs in your<br>PostgreSQL<br><span class="hit">skills file</span><span class="cursor"></span>

<div class="date">Konstantin Gredeskoul, kig.re</div>

Note: [0:00, 30 seconds] Your coding agent writes a lot of your migrations now. This talk is about the file that tells it how. I start with the one question every other rule depends on, then walk through the file I use, rule by rule. You can copy the structure tonight.

---

<div class="eyebrow">First, a show of hands</div>

## Six questions before I start

<div class="quiz">

<p class="fragment current-visible">Who writes code with AI as an assistant?</p>

<p class="fragment current-visible">Who barely writes code any more? You spec it, the agent writes it, you review it.</p>

<p class="fragment current-visible">Of that second group: who has read every <code>SKILL.md</code> they installed? Be honest.</p>

<p class="fragment current-visible">Who is picky about what lands in <code>~/.claude/skills</code>?</p>

<p class="fragment current-visible">Same question for your plugins, commands and workflows.</p>

<p class="fragment current-visible">And who has written a skill, command or plugin they use every week?</p>

</div>

Note: [0:30 to 1:15] Six questions, hands up. One: who writes code with AI as an assistant? Two: who barely writes code any more, where you spec it, the agent writes it, and you review? Keep your hands up. Three: of that group, who has read every SKILL.md they installed? Be honest. Four: who is genuinely picky about what lands in their skills directory? Five: same question for plugins, commands and workflows, which nobody audits either. Six: who has written a skill or a command they use every week? Look around. That last group is small, and the rest of this talk is about joining it.

---

<div class="eyebrow">Step zero</div>

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

<div class="eyebrow">Step zero</div>

## The answer changes the rules

<table class="class-table">
<thead>
<tr><th></th><th>PG-lax</th><th>PG-traditional</th><th class="hot">PG-strict</th><th>PG-analytics</th></tr>
</thead>
<tbody>
<tr class="fragment"><td>Rough throughput</td><td>2k to 10k tx/s</td><td>500 to 5k tx/s</td><td class="hot">100 to 1k tx/s</td><td>Under 10 queries/s</td></tr>
<tr class="fragment"><td>Deletes</td><td>Physical</td><td>Decide per table</td><td class="hot">Logical only, <code>deleted_at</code></td><td>Rare</td></tr>
<tr class="fragment"><td><code>ON DELETE</code></td><td><code>CASCADE</code></td><td>Stated on every key</td><td class="hot">Custom, sets <code>deleted_at</code></td><td>Rarely matters</td></tr>
<tr class="fragment"><td>Row locking</td><td><code>lock_version</code> is fine</td><td>Where money moves</td><td class="hot"><code>FOR UPDATE</code> by default</td><td>Few writers</td></tr>
<tr class="fragment"><td>Query mix</td><td>Many small reads</td><td>Small reads and writes</td><td class="hot">Small reads and writes</td><td>A few heavy, long queries</td></tr>
</tbody>
</table>

<div class="fragment">

```markdown
<!-- AGENTS.md -->
Database class: PG-strict. Logical deletes only. Ask before any physical DELETE.
```

</div>

<div class="kill fragment">Skip this line and your agent adds ON DELETE CASCADE to a ledger.</div>

Note: [1:30 to 2:45] Here is why the class comes first. The same question gets four different answers. Should a delete remove the row? In a game, yes. In a ledger, never. What happens to child rows when a parent goes away? Cascade in a game, a custom soft delete in a bank. Do you lock rows before you update a balance? In a strict app, always. So the first rule in my skill says: ask the human for the class, or read it from the spec, and write it in AGENTS.md. One line. Every later decision reads it. Without that line, an agent will happily put a cascading delete on your ledger table. The last two rows are the shape of the load. A medium social network runs thousands of small transactions a second, almost all reads. An online store runs fewer, because more of them write. A ledger runs fewer still, because rows are locked while money moves. A warehouse may run under ten queries a second, and each one takes seconds or minutes. These are orders of magnitude on one primary, not benchmarks. Measure your own.

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

<div class="eyebrow warning">Rule 1: migrations</div>

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

<div class="eyebrow warning">Rule 2: NOT NULL</div>

## Add NOT NULL in three migrations, not one

<p class="lede">To enforce that <code>invoices.currency</code> is never null, <code>change_column_null</code> takes the strongest lock and reads all 200 million rows. The table is unavailable until it finishes.</p>

<div class="steps">

<div class="card fragment">
<div class="num">1</div>
<div>
<div class="kicker">Add the rule, lock for an instant</div>
<p><code>CHECK (currency IS NOT NULL) NOT VALID</code> guards every new row and reads none of the old ones.</p>
</div>
</div>

<div class="card fragment">
<div class="num">2</div>
<div>
<div class="kicker">Prove it, in its own migration</div>
<p><code>VALIDATE CONSTRAINT</code> reads all 200 million rows under a weaker lock. Your app keeps reading and writing.</p>
</div>
</div>

<div class="card fragment">
<div class="num">3</div>
<div>
<div class="kicker">Now set NOT NULL</div>
<p>PostgreSQL 12 and later accept the validated check as the proof, skip the scan, and flip a flag.</p>
</div>
</div>

</div>

<p class="fragment">Three short locks instead of one long one, and the same column in the end.</p>

Note: [6:00 to 7:00] Rule two. Adding a column with a default is safe since PostgreSQL 11. Adding null false to an existing column is not. The agent will reach for change_column_null, which locks the whole table and scans every row to prove there are no nulls. On a big table, that is an outage. The safe version is three migrations. First, add a check constraint marked NOT VALID, which takes a brief lock and reads nothing. Second, validate it, which scans the table but lets writes continue. Third, set NOT NULL. PostgreSQL sees the validated check and skips the scan. Nobody remembers this at 11 at night, so write it down.

---

<div class="eyebrow warning">Rules 3, 5, 6, and 8</div>

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

<div class="eyebrow warning">Rule 4: primary keys</div>

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

<div class="eyebrow warning">Rule 7: soft deletes</div>

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

<div class="eyebrow">Indexes</div>

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

<div class="eyebrow warning">Rails models</div>

## A foreign key points at one table. Pick accordingly.

<div class="three-grid rise">

<div class="card">

<div class="kicker">One table, many classes</div>

### STI

A real key can point at `carts.id`. It just cannot say *which* subclass, so Postgres accepts a `smoothies.banana_id` that points at a strawberry. Add a `CHECK` for that.

</div>

<div class="card">

<div class="kicker">Rails 6.1 and later</div>

### Delegated types

Each class gets its own table, and a join row points at whichever one applies. That key is real and enforced, and each table can require its own columns.

</div>

<div class="card amber">

<div class="kicker">The one that gives up the key</div>

### Polymorphic

`edible_id` points at whatever `edible_type` names on that row, and no foreign key can express that. You trade enforcement for convenience.

</div>

</div>

<p class="fragment">Store <code>banana</code> in the type column, never <code>Fruit::Banana</code>, or renaming a module becomes a data migration. Index <code>(edible_id, edible_type DESC)</code>.</p>

Note: [11:15 to 12:15] Rails gives you three ways to map many classes onto tables, and they differ in exactly one thing: whether you still get a real foreign key. Single table inheritance is one table with a type column. Other tables can point a genuine key at it, but that key cannot say which subclass, so the database will happily let a smoothie reference a strawberry as its banana. If the subclass matters, add a check constraint. Delegated types, which arrived in Rails 6.1, give each class its own table with a join row pointing at it, so every reference is enforced, and each table can make its own columns required. Polymorphic associations give that up entirely: the id column points at whichever table the type column names, and there is no such foreign key in SQL. And in all three, store a short lowercase token in the type column, because a module rename otherwise turns into a data migration across millions of rows.

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

### N+1 queries

`strict_loading` raises in development instead of running 400 queries in production.

</div>

<div class="card amber">

### Wraparound

An open snapshot blocks freezing. Turning autovacuum off does not.

</div>

</div>

Note: [12:15 to 13:00] SKILL.md stays short on purpose. The rest lives in the reference file, which the agent reads before it designs a schema. A few examples. Two SELECTs in one transaction can disagree, so read-modify-write needs FOR UPDATE. Money is integer cents with a currency code. Timeouts are set on the database role, so connection pooling cannot drop them. The pool on the database side is small, around twenty connections for eight cores. Strict loading turns a hidden N plus one into an exception while you are still writing the code. And transaction ID wraparound comes from a snapshot someone left open, not from autovacuum being off. The whole file is in the blog post.

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

Note: [13:00 to 13:50] Here is the recipe. Start with the class, because every rule depends on it. Write a description that triggers on the words you actually type. Keep SKILL.md short, and fill it with the rules whose failure is silent: the lock timeout, the three-step NOT NULL, the partial index tradeoff. Put the long explanations in a reference file. Then keep it alive. Each outage you survive is a line in the file. If a new PostgreSQL release contradicts a rule, the file tells the agent to stop and ask you. And yes, run the unused-index query. You will find something.

---

<div class="eyebrow">Bonus</div>

## But Wait, There is more!

<p style="float: right; margin-top: -100px;">Watch for <a href="https://dry-cli.tools">dry-cli.tools</a> coming online soon!</small>

<p class="lede">How I run my Software Team</p>

<div class="three-grid rise">

<div class="card">

<div class="kicker">Installer</div>

### agentilda-ai-setup

Installs skills, plugins, commands, and hooks for any agent. Take only the parts you want, from any repo.

<p class="repo"><a href="https://github.com/kigster/agentilda-ai-setup">github.com/kigster/agentilda-ai-setup</a></p>

</div>

<div class="card">

<div class="kicker">Ruby gem, installs the <code>tilda</code> CLI</div>

### agentilda

Does most of the work. It writes and refines a spec, turns it into a plan, builds it, opens the PR, and loops on review until it is approved.

`tilda install skills` teaches your agent to use it.

<p class="repo"><a href="https://github.com/kigster/agentilda">github.com/kigster/agentilda</a></p>

</div>

<div class="card">

<div class="kicker">Ruby gem, installs the <code>alo</code> CLI</div>

### agent-lock

Lets concurrent agents lock part of the tree to themselves. It uses local Redis when it can, and the file system when it cannot.

<p class="repo"><a href="https://github.com/kigster/agent-lock">github.com/kigster/agent-lock</a></p>

</div>

</div>

Note: [13:50 to 14:40] One more thing, if you want to see how the skill file fits into a bigger setup. agentilda-ai-setup installs skills, plugins, commands, and hooks for whichever agent you use, and lets you pick only the parts you want from other repos. agentilda is the Ruby gem that does the heavy lifting. Its tilda command takes a spec, refines it, plans it, builds it, opens a pull request, and runs review until the work is approved. Run tilda install skills and your agent learns how to use it. agent-lock is the small one I cannot live without. I run ten agents at once, and it lets each of them lock the part of the tree it is writing, with Redis or the file system underneath.

---

<!-- .slide: class="center final-slide" -->

# Thanks! | <small><a href="https://kig.re/skills">kig.re</a></small>

<div class="author-section">
  <div class="questions">
     Was this helpful?<br>
     What could I have done better?<br>
      <small>Download my PG skill tomorrow from <a href="https://kig.re/skills">kig.re/skills</a></small>
     <hr>
     I will soon be for hire!<br>
     (415) 265 1054 (Talk to me!)
    </div>
  <img src="assets/img/kig.jpeg" alt="Konstantin Gredeskoul" class="author-photo">
</div>

<div class="author-credit"><a href="https://kig.re/2026/08/19/condensing-twenty-years-of-wisdom-in-one-markdown.html">Condensing twenty years of wisdom in one markdown, on kig.re</a></div>

Note: [14:40 to 15:00] The whole file is in that post. Take it, argue with it, and write your own. I would like to hear the arguments, especially if you measured a HOT number different from 174.
