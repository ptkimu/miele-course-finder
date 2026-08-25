#!/usr/bin/env bash
# index.html から配布物を生成する（index.html が唯一の編集対象）
set -e
cd "$(dirname "$0")"

# Netlify Drop 用
mkdir -p out
cp index.html out/index.html
printf 'User-agent: *\nDisallow: /\n' > out/robots.txt

# Artifactプレビュー用（<head> を剥いだ版）
{
  echo '<title>ミエーレ コース診断</title>'
  sed -n '/^<body>$/,/^<\/body>$/p' index.html | sed '1d;$d'
} > core.html

echo "built: out/index.html, out/robots.txt, core.html"
