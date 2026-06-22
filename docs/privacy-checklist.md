# Privacy Checklist for Public Demos

Use this before recording, streaming, publishing screenshots, or pushing the repo.

## Redact or Replace

- Replace real email addresses with `you@example.com`.
- Replace subscription IDs with `00000000-0000-0000-0000-000000000000`.
- Blur tenant IDs, directory names, and account names.
- Avoid showing Azure Portal profile menus.
- Avoid showing exact cost history unless it is intentionally part of the demo.
- Do not show storage account keys, SAS tokens, service principal secrets, refresh tokens, or `.azure` profile files.

## Repo Hygiene

- Keep `terraform.tfvars` out of git.
- Keep `.env` and `.env.*` out of git except `.env.example`.
- Do not include real subscription IDs or emails in examples.
- Keep public `billing-data.json` free of subscription IDs and tenant IDs.
- Run secret scanning before publishing.

## About Subscription IDs

A subscription ID is not a secret by itself. Someone cannot access your Azure resources with only that ID. Still, it is a stable account identifier and can be combined with other information, so do not show it in public videos or committed examples unless there is a strong reason.

## Safer Demo Strategy

- Use mock data for the first walkthrough.
- Show Azure CLI commands with placeholder values.
- If showing real CLI output, clear the screen or crop/redact identifiers.
- Trigger budget behavior by lowering demo budget thresholds instead of creating paid compute to burn money.
