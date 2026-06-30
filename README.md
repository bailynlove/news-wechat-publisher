# news-wechat-publisher

Codex skill for generating a GitHub / Hugging Face / arXiv trend digest and publishing it to a WeChat Official Account draft box.

It is built around a reusable article template and a small wrapper around [`@wenyan-md/cli`](https://github.com/caol64/wenyan-cli).

## What It Does

- Turns daily or weekly AI/open-source/research signals into a WeChat-ready Markdown article.
- Uses a mobile-friendly trend digest template instead of a raw link list.
- Validates that the article has no unreplaced `{{...}}` placeholders.
- Adds missing wenyan frontmatter when possible.
- Publishes to the WeChat draft box for final review in the official backend.

## Repository Layout

```text
news-wechat-publisher/
├── SKILL.md
├── README.md
├── LICENSE
├── assets/
│   ├── default-cover.jpg
│   └── trend-digest-template.md
├── agents/
│   └── openai.yaml
└── scripts/
    └── publish.sh
```

## Requirements

- Node.js
- `wenyan` CLI:

```bash
npm install -g @wenyan-md/cli
```

- WeChat Official Account credentials:

```bash
export WECHAT_APP_ID=your_app_id
export WECHAT_APP_SECRET=your_app_secret
```

You can also put those two variables in either:

- `.env` in this repository
- `~/.wechat-publisher.env`

The public IP of the machine running the command must be in the WeChat Official Account IP whitelist.

## Use With Codex

Ask Codex to use the skill, for example:

```text
Use $news-wechat-publisher to search today's GitHub, Hugging Face, and arXiv AI trends, draft a WeChat article, and publish it to the draft box.
```

The skill will:

1. Search current sources.
2. Draft with `assets/trend-digest-template.md`.
3. Save a Markdown article with frontmatter.
4. Run `scripts/publish.sh`.

## Manual Publishing

Create an article:

```markdown
---
title: Agent 工具链正在进入评测时代
cover: ./assets/default-cover.jpg
---

# Agent 工具链正在进入评测时代

正文...
```

Validate without publishing:

```bash
bash scripts/publish.sh article.md --dry-run
```

Publish to the draft box:

```bash
bash scripts/publish.sh article.md
```

Optional theme controls:

```bash
bash scripts/publish.sh article.md --theme lapis --highlight solarized-light
```

## Drafting Standard

The article should have:

- One clear thesis.
- 3 to 5 key findings.
- A short paper radar section.
- Trend interpretation, not just links.
- Three concrete actions for the reader.
- Source links for every highlighted item.

Avoid exposing private paths, internal Agent routing, credentials, or unfinished placeholders.

## Troubleshooting

- `wenyan-cli is not installed`: run `npm install -g @wenyan-md/cli`.
- `Missing WeChat credentials`: set `WECHAT_APP_ID` and `WECHAT_APP_SECRET`.
- WeChat API rejects the request: check the Official Account IP whitelist.
- The script stops on `{{...}}`: finish replacing template placeholders before publishing.
- Draft published but not visible to readers: this command only creates a draft; publish it manually from [mp.weixin.qq.com](https://mp.weixin.qq.com/).
