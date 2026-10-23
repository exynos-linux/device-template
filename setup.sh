#!/bin/sh
# Install postmarketOS Duranium on this port's device (config.toml) from
# this Linux PC. Guide: docs/INSTALL.md; ./setup.sh --help
exec bash "$(dirname "$0")/scripts/installer/setup" "$@"
