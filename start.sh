#!/data/data/com.termux/files/usr/bin/sh

URL="https://example.com/file.js"

if ! command -v node >/dev/null 2>&1; then
  pkg update -y
  pkg install nodejs -y
fi

npm install ws

if command -v curl >/dev/null 2>&1; then
  curl -L "$URL" -o "index.js"
elif command -v wget >/dev/null 2>&1; then
  wget "$URL" -O "index.js"
else
  echo "curl or wget not found."
  exit 1
fi