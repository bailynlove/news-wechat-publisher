---
name: news-wechat-publisher
description: Generate a WeChat Official Account trend digest from GitHub, Hugging Face, arXiv, Hacker News, or official-source research signals, then publish the Markdown article to the WeChat draft box with wenyan-cli. Use when the user wants an Agent to turn daily/weekly AI, open-source, or paper trends into a WeChat draft.
---

# News WeChat Publisher

Use this skill to turn trend intelligence into a WeChat Official Account draft.

## Workflow

1. Gather current signals from the requested sources.
   - Use fresh sources for GitHub, Hugging Face, arXiv, Hacker News, official blogs, and project repositories.
   - Keep source links for every highlighted item.
   - Prefer primary sources over commentary.
2. Draft the article with `assets/trend-digest-template.md`.
   - Keep one main thesis.
   - Select 3 to 5 key findings.
   - Use short mobile-friendly sections instead of wide tables.
   - Remove internal routing, private file paths, private todos, and unreplaced placeholders.
3. Add wenyan frontmatter at the top:

   ```markdown
   ---
   title: 文章标题
   cover: ./assets/default-cover.jpg
   ---
   ```

   Use a local or remote cover image. The default cover is available at `assets/default-cover.jpg`.

4. Save the final article as a Markdown file.
5. Publish to the WeChat draft box:

   ```bash
   bash scripts/publish.sh path/to/article.md
   ```

   Optional:

   ```bash
   bash scripts/publish.sh path/to/article.md --theme lapis --highlight solarized-light
   bash scripts/publish.sh path/to/article.md --dry-run
   ```

## Environment

`scripts/publish.sh` requires `wenyan` from `@wenyan-md/cli`.

If `wenyan` is missing, install it:

```bash
npm install -g @wenyan-md/cli
```

Credentials can be provided in any of these places:

- Environment variables: `WECHAT_APP_ID` and `WECHAT_APP_SECRET`
- `.env` in the repository root
- `~/.wechat-publisher.env`

The WeChat Official Account backend must whitelist the current public IP.

## Drafting Rules

- Do not publish a raw list of links. Always synthesize a thesis.
- Do not make GitHub stars the only signal; explain why the item matters.
- Do not use clickbait phrases such as "震惊", "炸裂", or "一夜之间".
- Do not expose private Agent names, local archive paths, credentials, or internal routing.
- If the article still contains `{{...}}` placeholders, stop and finish the draft before publishing.
- Use Beijing time for dates and retrieval windows unless the user requests another timezone.

## Validation

Before publishing, run:

```bash
bash scripts/publish.sh path/to/article.md --dry-run
```

The script checks the file, credentials, frontmatter, missing placeholders, and `wenyan` availability. A real publish pushes the article to the WeChat draft box, not directly to subscribers.
