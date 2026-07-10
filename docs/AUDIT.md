# Bip Audit Mirror

`/audit/actions.jsonl` is the Hermes-era governance mirror for Bip actions. The Docker
Compose `audit` volume is private to the stack, mounted only into Hermes, and the entrypoint
keeps `/audit` at `0700` with `actions.jsonl` at `0600`.

Hermes shell hooks append one JSON object per line:

- `pre_approval_request` -> `event: "proposal"`
- `post_approval_response` -> `event: "decision"` with `outcome` such as `approved`,
  `deny`, or `timeout`
- `post_tool_call` -> `event: "execution"` with tool input and result details truncated
  for log safety

Use `make audit` to tail `/audit/actions.jsonl` from the running Hermes container.

## Known Gaps

`unsupported_fields` records audit fields that Hermes did not expose in the hook payload.
Today that includes `telegram.approval_message_id` and `telegram.approval_chat_id` for
approval request/response events. Stage 5 send/deploy/spend hands must remain disabled
until any required unsupported_fields are either exposed by Hermes or replaced by an
equivalent correlation field.
