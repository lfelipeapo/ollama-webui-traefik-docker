#!/usr/bin/env bash

source .env

usage() {
    echo "Usage: $0 [local_dir] [remote_dir]" >&2
    echo "Default local_dir: ./" >&2
    echo "Default remote_dir: root@$DOMAIN:/root/" >&2
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ -z "$DOMAIN" ]; then
    echo "Error: DOMAIN is not set. Configure it in the .env file." >&2
    exit 1
fi

LOCAL_DIR="${1:-./}"
REMOTE_DIR="${2:-root@$DOMAIN:/root/}"

scp -r "$LOCAL_DIR" "$REMOTE_DIR"
