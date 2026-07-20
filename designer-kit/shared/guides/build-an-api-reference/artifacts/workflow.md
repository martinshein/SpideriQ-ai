# Build an API reference (docs theme)

When the user wants a Stripe/ReadMe/Mintlify-class API reference on SpiderPublish, do these steps in order. The result is a three-column reference — a navigation tree, prose + parameters, and a **pinned, tabbed code panel** (cURL, Python, JavaScript, Go) — with **Try it** and **Ask AI**.

## Step 1: confirm session binding

Run `auth_whoami`. The `client_id` must match the `project_id` in `./spideriq.json`. If not, run `npx @spideriq/cli use <project>` first.

## Step 2: import the OpenAPI spec

Call `content_import_openapi` with either a spec URL or pasted spec content (OpenAPI 3.x or Swagger 2.0). Use `dry_run: true` first to preview the planned pages (one section + one page per tag), then run it for real. The importer stores **structured per-operation data** (method, path, parameters, request and response shapes, and code samples) — that structure is what the docs theme renders. Re-importing the same spec is idempotent: it owns the API-Reference section and leaves your other docs untouched.

## Step 3: apply the docs theme

Apply the `docs` theme to the project:

```
template_apply_theme({ theme: "docs" })
```

`template_list_themes` shows the available themes. Applying a theme **overwrites per-file template edits** for the project, so it runs behind a dry_run → confirm gate — pass the confirm token to commit.

## Step 4: deploy

Deploy the project (`content_deploy_site`, or the dashboard deploy). Every operation now renders with its method badge, path, parameters, request/response shapes, and ready-to-copy code in four languages; **Try it** sends a real request and shows the response; **Ask AI** answers from your published docs.

## Notes

- Put the API reference on its own project (e.g. a `docs.` subdomain) so the docs chrome is the whole site.
- Full guide: https://publish.spideriq.ai/docs/build-an-api-reference
