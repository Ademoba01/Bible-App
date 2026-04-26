#!/bin/bash
# Pre-strip FinderInfo xattr from project directories (excluding .git and build caches)
# This prevents Flutter's built-in xattr step from hanging
cd "$(dirname "$0")/.."
find . -not -path './.git/*' -not -path './build/*' -not -path './.dart_tool/*' -exec xattr -d com.apple.FinderInfo {} 2>/dev/null \;
echo "xattr cleanup complete"
