#!/data/data/com.termux/files/usr/bin/sh

URL="https://raw.githubusercontent.com/Horizon-Developments/hyperionX/main/server.js"
DIR="./HyperionX"

if ! command -v node >/dev/null 2>&1; then
  pkg update -y
  pkg install nodejs -y
fi

mkdir -p "$DIR"

cd "$DIR"

if command -v curl >/dev/null 2>&1; then
  curl -L "$URL" -o "index.js"
elif command -v wget >/dev/null 2>&1; then
  wget "$URL" -O "index.js"
else
  echo "curl or wget not found."
  exit 1
fi

npm install ws

cd $HOME

echo "usage: node $(realpath "$DIR") <authtoken> <domain> <owner_password> <client_password>"
echo "create a free ngrok domain and authtoken at https://dashboard.ngrok.com/signup"