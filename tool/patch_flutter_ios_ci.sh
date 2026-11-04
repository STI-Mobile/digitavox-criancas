#!/usr/bin/env bash
set -euo pipefail

# Backport oficial para a descoberta do VM service no simulador do CI.
# Consulte patches/README.md antes de atualizar a versão do Flutter.
: "${FLUTTER_ROOT:?FLUTTER_ROOT precisa apontar para o SDK isolado do CI}"
if [ "${CI:-}" != "true" ]; then
  echo 'Este ajuste só pode ser aplicado ao SDK do CI.' >&2
  exit 1
fi

python3 - "$FLUTTER_ROOT/bin/cache/flutter.version.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as metadata:
    version = json.load(metadata)['frameworkVersion']
if version != '3.47.2':
    raise SystemExit(f'Reavalie o backport antes de usar Flutter {version}.')
PY

patch_path="$(cd "$(dirname "$0")" && pwd)/patches/flutter-3.47.2-ios-log-stream.patch"
if ! git -C "$FLUTTER_ROOT" apply --reverse --check "$patch_path" 2>/dev/null; then
  git -C "$FLUTTER_ROOT" apply --check "$patch_path"
  git -C "$FLUTTER_ROOT" apply "$patch_path"
fi
# O flutter-action pode restaurar um snapshot compilado antes do backport.
rm -f "$FLUTTER_ROOT/bin/cache/flutter_tools.snapshot" "$FLUTTER_ROOT/bin/cache/flutter_tools.stamp"
