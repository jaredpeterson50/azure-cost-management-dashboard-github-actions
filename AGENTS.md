# Azure Billing Dashboard Agent Guide

## Project Purpose
This project is an Azure monthly billing dashboard. It tracks current month spend against a configurable budget target and shows alert state for budget thresholds.

Default budget behavior:
- Monthly budget target: `$2.60`
- Alert thresholds: `50%`, `75%`, `90%`
- Reset cadence: monthly

## Stack
- React
- Vite
- TypeScript
- Vitest for calculation and component tests

## UX Direction
- Build the dashboard as the first screen. Do not add a marketing landing page.
- Keep the interface compact, operational, and easy to scan.
- Make monthly spend, budget target, percent used, threshold state, and alert status obvious.
- Use restrained visual styling suitable for an operations dashboard.

## Integration Direction
- Use Azure Cost Management as the future source for spend data.
- Prefer Azure Budget alerts for email notifications.
- Use Azure Functions or Logic Apps only when custom routing, templates, or workflow behavior is required.

## Coding Rules
- Keep changes small and focused.
- Prefer existing components, helpers, and local patterns once they exist.
- Do not hard-code secrets, Azure credentials, tenant IDs, or subscription IDs.
- Use environment variables for tenant, subscription, scope, and integration settings.
- Add or update tests around threshold calculations and alert state logic.
- Keep mock data isolated behind a boundary that can later be replaced by Azure Cost Management data.
