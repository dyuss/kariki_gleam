gleam run -m lustre/dev build app --minify
mkdir -p dist
cp index.html dist/index.html
cp -r priv dist/priv
cp -r assets dist/assets
sed -i '' 's|priv/static/kariki.mjs|priv/static/kariki.min.mjs|' dist/index.html