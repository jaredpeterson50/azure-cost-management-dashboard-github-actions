# Safety and Audit Tools

## Terraform Quality Gates

Use these before applying infrastructure changes:

- `terraform fmt -check`: formatting consistency.
- `terraform validate`: Terraform syntax and provider schema validation.
- `terraform plan`: human review of exactly what Azure will change.
- `terraform show -json plan.out`: machine-readable plan for CI policy checks.

## Security Scanners

Recommended scanners for Terraform and Azure IaC:

- Checkov: policy-as-code scanner for Terraform, secrets, and cloud misconfigurations.
- Trivy: scans Terraform, containers, dependencies, and secrets in one toolchain.
- tfsec: Terraform-focused static analysis. Many teams now use Trivy for the same rule family.
- Terrascan: policy checks for Terraform and other IaC formats.
- GitHub secret scanning or Gitleaks: catches committed tokens and credentials.

## Azure-Native Controls

Use these for production-style governance:

- Microsoft Defender for Cloud: secure score, recommendations, and regulatory posture.
- Azure Policy: enforce required tags, TLS versions, allowed regions, and SKU restrictions.
- Azure Advisor: cost, reliability, performance, and security recommendations.
- Microsoft Cost Management budgets: native spend alerts.
- Activity Log alerts: alert on resource creation, deletion, and policy changes.

## Practical Rules for This Project

- Keep static hosting in Terraform and app deploys in `npm run deploy:azure`.
- Tag any intentionally stoppable demo compute with `AutoShutdown=true`.
- Do not tag the dashboard storage account with `AutoShutdown=true`.
- Run a Terraform plan and at least one IaC scanner before applying infrastructure changes.
- Prefer lowering the test budget to trigger alerts over creating compute just to spend money.