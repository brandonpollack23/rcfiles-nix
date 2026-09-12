#!/bin/sh
set -eu

PLUGIN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$PLUGIN_DIR/../../reinstall_plugins.sh" --if-changed
