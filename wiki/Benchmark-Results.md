# Benchmark results

Performance advice is often generic, such as "jobs are slow" or "use a real
database". These experiments measured what actually changes response times on a
small PSU instance. They ran on one workstation, so treat the numbers as
direction rather than promises.

## PSU runtime: the habits that matter

- **Cache only the fields you need.** Caching 100 whole process objects took
  4 seconds; caching three selected fields took 6 milliseconds.
- **Jobs cost about 1.5 s to start,** but they held up better than endpoints when
  several long requests arrived at once.
- **Stop unwanted output at its source.** That saved about a second per job.
- **Collect loop output with `$rows = @(foreach ...)`,** not `+=`.
- **Build a lookup table only when you'll look things up repeatedly.**

[Full PSU results](https://github.com/ingenite/psu-agent-reference/blob/main/tools/benchmarks/Findings.md)

## Databases: SQLite, PostgreSQL or SQL Server?

For a small PSU app, **how you use the database matters more than which one you
pick**. PSU's own HTTP handling adds 16–19 ms to every request, which hides
sub-millisecond engine differences.

| If you need… | Choose |
| --- | --- |
| One server, no extra service to run | SQLite |
| Fast multi-row reads with many readers | PostgreSQL |
| Many simultaneous writers, or Windows authentication | SQL Server |

Whatever you choose, batch your writes, reuse connections, and return only the
fields you need.

[Full database results, charts and method](https://github.com/ingenite/psu-agent-reference/blob/main/tools/benchmarks/DatabaseProviders.md)
