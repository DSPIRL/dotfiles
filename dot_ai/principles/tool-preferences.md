# Tool Preferences

These are the user's defaults, not requirements. Choose tools for the job, not merely to match this list.

## Preferred Tools

- Backend language: Rust, especially for long-lived services, CLI tools, performance-sensitive work, or code shared with Tauri. For small CRUD apps and experiments, consider a TypeScript backend when one language end-to-end materially reduces development effort. Python is a reasonable exception for data/ML-heavy work.
- Frontend language: TypeScript.
- Frontend framework and build tooling: Svelte + Vite for client-side apps and Tauri frontends. Prefer SvelteKit for websites needing routing, server rendering, server-side endpoints, or full-stack features; it uses Vite too. For Tauri, ensure the frontend can run without a runtime web server rather than assuming server-only SvelteKit features will work.
- Frontend UI: shadcn-svelte as the preferred component source. Adopt suitable components and blocks as needed, not the whole kit upfront. The copied components become project-owned code; check accessibility, compatibility, and maintenance before adopting third-party blocks. Use https://shadcn-svelte.com for Svelte components; https://ui.shadcn.com provides the React kit and design ideas, not drop-in Svelte components. Account for the smaller Svelte integration ecosystem when assessing fit.
- JavaScript runtime and package management: Node.js + npm by default for broad ecosystem and deployment compatibility. Consider Bun when its speed or integrated tooling provides a concrete benefit and the project supports it. Use one package-management workflow and lockfile per project; do not turn every project into a runtime comparison exercise.
- Desktop framework: Tauri with Rust and, when a web UI is needed, the preferred frontend stack. Assess system-WebView differences, native dependencies, and packaging on the target operating systems. Prefer a browser app when desktop integration is unnecessary; consider alternatives when consistent cross-platform rendering or complex native UI requirements outweigh Tauri's benefits.
- Environment tooling: mise first for development tool versions and tasks; Nix complements it only for needs mise cannot handle, such as system/native dependencies or reproducible environments beyond tool-version management. Nix may provide mise. Assign one owner for each tool version rather than selecting the same compiler or runtime independently in both.

This is a menu, not a requirement to include every tool. Do not add a backend, desktop wrapper, or Nix configuration unless the project needs one.

## Machine Tools

Commonly installed: `rg`, `fd`, `bat`, `jq`, and `yq`. Some machines also have `az` and `aws`. Check availability when needed; fall back if absent. Their presence is not a preference or permission to install them, and does not make them project requirements.

## Before Starting a New Project

Before scaffolding, installing dependencies, or implementing:

1. Read the goal and constraints. Ask only questions that materially affect the stack choice.
2. Give a brief stack assessment: recommend tools, explain why they fit, and identify meaningful drawbacks or mismatches with these preferences. Consider scope, deployment targets, ecosystem support, and maintenance cost.
3. If another tool is a better fit, say so and explain the concrete benefit. Do not manufacture alternatives when the defaults fit well.
4. Wait for the user's agreement on the stack unless they have already explicitly selected or approved it. A preferred tool is not prior approval.

Keep this assessment short; do not turn it into an architecture study unless requested.

## Existing Projects

Personal tool preferences primarily guide new projects. In existing projects, follow the established stack, package manager, environment tooling, and conventions—even when they differ from these preferences. Respect project instructions and recorded decisions. Propose changes only when explicitly requested or when a concrete project need justifies them, and obtain agreement before migrating or introducing different tooling. These preferences alone do not justify a migration or extra tooling. Apply the same assessment and agreement step when proposing a substantial stack change, not for routine work within an established stack.

When the choice is durable, preserve its rationale in the project's existing `CONTEXT.md` or ADR conventions so future agents do not reopen it without new evidence.
