# Documentation maintenance

## Preview locally

From the repository root, using Python 3.10 or newer:

```sh
python -m venv .venv
# Windows: .venv/Scripts/activate
# macOS/Linux: source .venv/bin/activate
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

## Validate

```sh
python -m mkdocs build --strict
```

Update API pages whenever the module changes, and review examples against the implementation. Build success checks documentation structure; it does not execute Luau in Roblox Studio.

## Publish with GitHub Pages

The `Documentation` workflow builds on pull requests and pushes to `main`. Only a push to `main` or a manual run on `main` deploys.

In repository **Settings → Pages → Build and deployment → Source**, select **GitHub Actions**. Push the documentation changes to `main`, then check the workflow under **Actions**. A successful deployment publishes at:

<https://teequis.github.io/Connex---Event-Connection-Manager/>

The workflow uses the built-in `GITHUB_TOKEN` with Pages and OIDC permissions in the deployment job. No personal access token or third-party deployment secret is required. Repository or organization policies may require approval of the `github-pages` environment.

See [GitHub's custom workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages) and [Material for MkDocs publishing guidance](https://squidfunk.github.io/mkdocs-material/publishing-your-site/).
