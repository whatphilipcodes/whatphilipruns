#!/bin/bash

set +x

CRED_FILE="$HOME/.git-credentials"

check_setup() {
    if [ -f "$CRED_FILE" ] && grep -q "github.com" "$CRED_FILE"; then
        if git config --global credential.helper | grep -q "store"; then
            if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
                return 0
            fi
        fi
    fi
    return 1
}

if check_setup; then
    printf "GitHub configuration is already complete.\n"
    exit 0
fi

printf "Enter GitHub Username (used for auth and commits): "
read -r GH_USERNAME

if [ -z "$GH_USERNAME" ]; then
    printf "Username cannot be empty. Aborting.\n"
    exit 1
fi

if ! git config --global user.email >/dev/null 2>&1; then
    printf "Enter Git User Email for commits: "
    read -r GIT_EMAIL
    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
    else
        printf "User Email cannot be empty.\n"
        exit 1
    fi
fi

printf "Enter GitHub Fine-Grained PAT: "
read -r -s GH_PAT
printf "\n"

if [ -z "$GH_PAT" ]; then
    printf "PAT cannot be empty. Aborting.\n"
    exit 1
fi

git config --global user.name "$GH_USERNAME"

touch "$CRED_FILE"
chmod 600 "$CRED_FILE"

sed -i '/github\.com/d' "$CRED_FILE" 2>/dev/null || true

printf "https://%s:%s@github.com\n" "$GH_USERNAME" "$GH_PAT" >> "$CRED_FILE"

git config --global credential.helper store

if check_setup; then
    printf "GitHub PAT and user profile have been successfully configured.\n"
else
    printf "Failed to configure GitHub PAT or user profile.\n"
    exit 1
fi