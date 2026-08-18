# Helm chart review

Run the **helm-chart-review** skill before you open or approve this PR. Full process: [Reviewing Helm Chart PRs with the helm-chart-review Skill](https://cognigy.atlassian.net/wiki/spaces/Engineering/pages/2665971746).

- **Author (Mode A, local checkout):** check out this branch, start Claude Code from the chart repo root, and ask: `Review the diff against main for the cognigy-ai-app chart against the Cognigy Helm chart guidelines.` Mode A renders the chart with `helm template` and audits RBAC, so run it before you request review.
- **Reviewer (Mode B, PR link):** with the Azure DevOps MCP connected, hand the skill this PR: `Review this PR against the Cognigy Helm chart guidelines and post the findings as PR comments: <paste this PR URL>`. Mode B checks the diff against the guidelines but does not render the chart, so confirm a Mode A render (or CI) before approving.

Needs a Confluence MCP with Engineering-space access. First-time install: `/plugin marketplace add Cognigy/agent-plugins` then `/plugin install helm-chart-review@Cognigy-skills`.

---

# Security
Please assess your changes and describe the potential impact of your change regarding the following checklist:
- [ ] A new ingress has been added which exposes functionality to the outside world
- [ ] A new service has been added to expose functionality inside of the cluster - is the service of type NodePort?
- [ ] Annotations for services or ingress objects have been changed
- [ ] No security relevant change
