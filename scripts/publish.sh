#!/usr/bin/env bash
# Publish a Markdown trend article to the WeChat Official Account draft box.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DEFAULT_THEME="lapis"
DEFAULT_HIGHLIGHT="solarized-light"
DEFAULT_COVER="$REPO_ROOT/assets/default-cover.jpg"

THEME="$DEFAULT_THEME"
HIGHLIGHT="$DEFAULT_HIGHLIGHT"
COVER="$DEFAULT_COVER"
DRY_RUN=0
ARTICLE=""
TEMP_FILE=""

red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }

cleanup() {
  if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage:
  bash scripts/publish.sh article.md [--theme lapis] [--highlight solarized-light] [--cover path-or-url] [--dry-run]

Examples:
  bash scripts/publish.sh drafts/2026-06-30-ai-trends.md
  bash scripts/publish.sh drafts/2026-06-30-ai-trends.md --theme lapis --highlight github
  bash scripts/publish.sh drafts/2026-06-30-ai-trends.md --dry-run
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --theme)
        THEME="${2:-}"
        shift 2
        ;;
      --highlight)
        HIGHLIGHT="${2:-}"
        shift 2
        ;;
      --cover)
        COVER="${2:-}"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -*)
        red "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        if [ -n "$ARTICLE" ]; then
          red "Only one article path is supported."
          exit 1
        fi
        ARTICLE="$1"
        shift
        ;;
    esac
  done

  if [ -z "$ARTICLE" ]; then
    usage
    exit 1
  fi
}

read_var_from_file() {
  local file="$1"
  local key="$2"

  [ -f "$file" ] || return 0

  sed -nE "s/^[[:space:]]*(export[[:space:]]+)?${key}=(['\"]?)([^'\"]*)\\2[[:space:]]*$/\\3/p" "$file" | head -1
}

load_credentials() {
  local files=(
    "$REPO_ROOT/.env"
    "$HOME/.wechat-publisher.env"
  )

  for file in "${files[@]}"; do
    if [ -z "${WECHAT_APP_ID:-}" ]; then
      WECHAT_APP_ID="$(read_var_from_file "$file" WECHAT_APP_ID || true)"
      export WECHAT_APP_ID
    fi
    if [ -z "${WECHAT_APP_SECRET:-}" ]; then
      WECHAT_APP_SECRET="$(read_var_from_file "$file" WECHAT_APP_SECRET || true)"
      export WECHAT_APP_SECRET
    fi
  done
}

require_tools() {
  if ! command -v wenyan >/dev/null 2>&1; then
    red "wenyan-cli is not installed."
    yellow "Install it with: npm install -g @wenyan-md/cli"
    exit 1
  fi
}

require_credentials() {
  load_credentials

  if [ -z "${WECHAT_APP_ID:-}" ] || [ -z "${WECHAT_APP_SECRET:-}" ]; then
    red "Missing WeChat credentials."
    cat <<'EOF'
Set these values in the environment, .env, or ~/.wechat-publisher.env:

  WECHAT_APP_ID=your_app_id
  WECHAT_APP_SECRET=your_app_secret

Also make sure the current public IP is whitelisted in the WeChat Official Account backend.
EOF
    exit 1
  fi
}

require_article() {
  if [ ! -f "$ARTICLE" ]; then
    red "Article file not found: $ARTICLE"
    exit 1
  fi

  if grep -q '{{[^}]*}}' "$ARTICLE"; then
    red "Article still contains template placeholders like {{...}}."
    exit 1
  fi
}

first_heading_title() {
  sed -nE 's/^#[[:space:]]+(.+)$/\1/p' "$ARTICLE" | head -1
}

frontmatter_title() {
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^title:[[:space:]]*/ {
      sub(/^title:[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  ' "$ARTICLE"
}

has_frontmatter() {
  [ "$(sed -n '1p' "$ARTICLE")" = "---" ]
}

frontmatter_has_cover() {
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^cover:[[:space:]]*/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$ARTICLE"
}

prepare_article() {
  if has_frontmatter && frontmatter_has_cover; then
    printf '%s\n' "$ARTICLE"
    return
  fi

  local title
  title="$(frontmatter_title)"
  if [ -z "$title" ]; then
    title="$(first_heading_title)"
  fi
  if [ -z "$title" ]; then
    title="AI 趋势情报"
  fi

  TEMP_FILE="$(mktemp "${TMPDIR:-/tmp}/wechat-draft.XXXXXX")"

  if has_frontmatter; then
    awk -v cover="$COVER" '
      NR == 1 && $0 == "---" { print; in_fm = 1; next }
      in_fm && $0 == "---" && !inserted { print "cover: " cover; inserted = 1; print; in_fm = 0; next }
      { print }
    ' "$ARTICLE" > "$TEMP_FILE"
  else
    {
      printf '%s\n' '---'
      printf 'title: %s\n' "$title"
      printf 'cover: %s\n' "$COVER"
      printf '%s\n\n' '---'
      cat "$ARTICLE"
    } > "$TEMP_FILE"
  fi

  printf '%s\n' "$TEMP_FILE"
}

main() {
  parse_args "$@"
  require_article
  require_tools
  require_credentials

  local publish_file
  publish_file="$(prepare_article)"

  green "Article is ready for WeChat draft publishing."
  printf '  file: %s\n' "$publish_file"
  printf '  theme: %s\n' "$THEME"
  printf '  highlight: %s\n' "$HIGHLIGHT"

  if [ "$DRY_RUN" -eq 1 ]; then
    yellow "Dry run complete. Nothing was published."
    exit 0
  fi

  wenyan publish -f "$publish_file" -t "$THEME" -h "$HIGHLIGHT"
  green "Published to WeChat draft box. Review it at https://mp.weixin.qq.com/"
}

main "$@"
