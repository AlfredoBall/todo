# Angular Environment Variable Handling

This project uses `@ngx-env/builder` to manage environment variables for both development and production builds. This approach is different from the default Angular CLI setup and is more similar to Vite or Create React App.

## How Environment Variables Are Injected

### 1. Development (`serve`)
- The Angular dev server (`@ngx-env/builder:dev-server`) **does not** automatically inject process environment variables (even if set by Docker, Aspire, or your shell) into the browser app.
- Instead, it reads variables from a `.env` file in the project root (e.g., `.env` in this directory).
- **You must have a valid `.env` file present before running `npm start` or `npm run serve`.**
- The `.env` file is typically generated automatically by the Aspire AppHost or a script (see below).

### 2. Production (`build`)
- In CI/CD (e.g., GitHub Actions), environment variables are injected into the build process by specifying them in the workflow file (see `.github/workflows/build.yml`).
- In `build.yml`, the `env:` block under the "Build Angular app" step sets each required `NG_APP_*` variable using values from Terraform outputs and pipeline secrets. These are available to the build process as environment variables.
- The `@ngx-env/builder:application` builder reads these environment variables at build time and injects them into the Angular app, making them available in the browser at runtime.
- Alternatively, if a `.env` file is present, it will also be read and used for variable injection.

## Why Not Use `WithEnvironment` in AppHost?
- The `.NET Aspire` AppHost can set environment variables for the process running the Angular dev server using `WithEnvironment`.
- However, **Angular CLI and `@ngx-env/builder` do not expose these process environment variables to the browser app**.
- Only variables in `.env` files (or `environment.ts` files, if used) are available to the Angular app at runtime.
- Therefore, for local development, a `.env` file is required.

## How the `.env` File Is Generated
- A PowerShell script (`generate-angular-dev-env.ps1`) is provided in `DevOps/Scripts/`.
- This script reads Terraform outputs and writes a `.env` file with all required `NG_APP_*` variables.
- The Aspire AppHost is configured to run this script automatically before starting the Angular app, so the `.env` file is always up to date.

## Summary
- **Development:** `.env` file required for local dev server; variables are not injected from process environment.
- **Production:** Variables can be injected via pipeline or `.env` file.
- **Do not edit `environment.ts` for secrets/config—use `.env` and the provided script.**

---

For more details, see the `generate-angular-dev-env.ps1` script and the Aspire AppHost configuration.
