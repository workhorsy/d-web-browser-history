
# Stop and exit on error
set -e

VERSION="2.0.0"

# Change dir to this scripts directory
script_dir=$(dirname $0)
cd $script_dir

# Generate readme
cd ..
sed 's/$VERSION/'$VERSION'/g' tools/README.template.md > README.md

# Generate documentation
dub --build=docs
mkdir docs/$VERSION
mv docs/web_browser_history.html docs/$VERSION/index.html
git add docs/$VERSION/

# Create release
git commit -a -m "Release $VERSION"
git push

# Create and push tag
git tag v$VERSION -m "Release $VERSION"
git push --tags
