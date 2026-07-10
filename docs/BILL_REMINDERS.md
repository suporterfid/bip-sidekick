# Gmail Bill Reminders

This is an advisory-only design for bill reminders and overdue account detection. It uses
Gmail read-only access through Google MCP and never pays, transfers money, changes account
state, or contacts vendors.

## Recognition Signals

Bip should treat a Gmail message as bill-related when it contains one or more strong
signals:

- Sender or subject indicates an invoice, bill, statement, receipt, payment due, failed
  payment, overdue notice, service suspension warning, or renewal.
- Body text includes due-date language such as `due by`, `vencimento`, `payment due`,
  `overdue`, `past due`, `invoice`, `fatura`, or `boleto`.
- The message includes amount-like text plus a vendor/account context.
- A later confirmation or receipt appears to settle the same vendor, account, amount, and
  billing period.

Weak marketing, promotion, or generic account emails should not become reminders unless a
due date or overdue signal is explicit.

## Reminder Fact Shape

When a bill is worth remembering, summarize it as a small fact in the daily note:

```text
bill: vendor=<name>; account=<optional>; amount=<optional>; due=<date or unknown>;
status=<upcoming|due_today|overdue|paid|uncertain>; confidence=<high|medium|low>;
source=<gmail message date/sender/subject>
```

If the amount, due date, or account is ambiguous, keep the field as `unknown` and lower the
confidence instead of inventing details.

## Deduplication

Use a stable dedupe key built from normalized vendor, account hint, amount when present,
and due date or billing period. Prefer the newest high-confidence message for the same key.

Do not spam repeated reminders for the same bill. A single daily brief may mention:

- overdue items,
- due-today items,
- upcoming items inside the next seven days,
- low-confidence items only when they look risky enough to ask the human to inspect.

Confirmation or receipt messages can mark an existing reminder as `paid` or remove it from
the urgent list, but Bip should still avoid claiming payment happened unless the message is
clear.

## Daily Brief Behavior

The daily brief may read Gmail for invoices, bills, confirmations, and overdue notices. It
may surface upcoming and overdue items in `/vault/daily/YYYY-MM-DD.md` and Telegram.

Bill reminders must stay advisory. Bip may say what appears due or overdue, cite the source
message, and propose that the human review or pay. Bip must not click payment links, pay
bills, send emails, call vendors, update calendars, delete messages, mark mail read, or
mutate external systems from this flow.

## Escalation

Use confidence handling:

- `high`: due date and vendor are clear, and the message is not just marketing.
- `medium`: due date or amount is inferred but plausible.
- `low`: important words appear, but the reminder may be ambiguous.

For low-confidence or high-risk messages, the daily brief should ask the human to inspect
the source message. Any future payment or account-management capability belongs in a
separate Stage 5 hand with least-privilege credentials, explicit manual approval, and
`/audit/actions.jsonl` coverage.
