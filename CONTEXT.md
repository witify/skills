# Witify Skills

A collection of agent skills (slash commands and behaviors) loaded by Claude Code and Codex. Skills are organized into buckets; the tracker skills reach ClickUp or Linear directly over MCP.

## Language

**Issue tracker**:
The tool that hosts a repo's issues — ClickUp by default, Linear when the project says so. Skills like `to-tickets`, `to-spec`, and `ship` read from and write to it over MCP.
_Avoid_: backlog manager, backlog backend, issue host

**Issue**:
A single tracked unit of work inside an **Issue tracker** — a bug, task, spec, or slice produced by `to-tickets`. ClickUp calls it a task.
_Avoid_: ticket (use only when quoting external systems that call them tickets)

**Parent**:
The **Issue** that `to-tickets` files its slices under — the spec from `to-spec`, or one created for the feature. It carries the cross-cutting context every slice shares, and its title becomes the PR's title: a set always ships as one PR.

## Relationships

- An **Issue tracker** holds many **Issues**
- A **Parent** is an **Issue** whose sub-tasks are the slices of one feature

## Flagged ambiguities

- "backlog" was previously used to mean both the *tool* hosting issues and the *body of work* inside it — resolved: the tool is the **Issue tracker**; "backlog" is no longer used as a domain term.
- "backlog backend" / "backlog manager" — resolved: collapsed into **Issue tracker**.
