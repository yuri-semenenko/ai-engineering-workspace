# Loop contract

Every loop is orchestration around existing engineering skills. It may sequence
and pass evidence between skills, but it must not duplicate or replace their
procedures. A loop is a readable canonical contract, not a runtime instruction.

Each `LOOP.md` must contain the following sections.

## Identity

Declare a stable identifier, human-readable name, version, and status. The
identifier is unique within `loops/` and matches its directory name.

## Purpose

State one sentence describing the goal, explicit non-goals, and success criteria.
The goal should make it possible to decide whether the loop's report was useful.

## Scope

Name the repositories, branches, pull requests, or paths the loop can inspect.
List excluded or protected paths, assumptions, and prerequisites.

## Inputs

Separate required and optional inputs. Say how incomplete, unavailable, or
ambiguous inputs are handled: report the gap, request clarification, or stop.

## Skill composition

List existing canonical skills or engineering steps in execution order. For each,
state its responsibility and the evidence it passes forward. Link skills rather
than restating their content.

## State

Name the state read at the start and written at the end, its owner, pruning rules,
and how human overrides are retained. State is per consuming project: it is not
persona data or methodology canon. Link `state.example.md`.

## Verification

Distinguish analysis from verification. Define the evidence required to mark a
finding confirmed, and how unavailable, failing, or inconclusive checks appear in
the output.

## Output

Link `output.md` and define a stable report schema, priority or severity
classification, evidence requirements, and the next recommended action.

## Limits

Set maximum items per run, maximum repeated attempts, and stop conditions. A loop
must stop rather than silently expanding into an unbounded investigation.

## Human handoff

List ambiguity, risk, missing evidence, protected-path, and required-decision
triggers that require a human to take over.

## Autonomy

Declare the level from [autonomy-levels.md](autonomy-levels.md), the actions the
loop may take, and the actions it must not take. Supported implementations may
use only L0 or L1. Every L1 loop needs an explicit write and outbound action
prohibition.
