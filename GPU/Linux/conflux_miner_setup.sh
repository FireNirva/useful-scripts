#!/bin/bash

# Capture the passed arguments for wallet address and worker name
MINING_POOL_ADDRESS=$1
CONFLUX_WALLET_ADDRESS=$2
WORKER_NAME=$3

# Get the latest release details using the GitHub API
LATEST_RELEASE=$(curl -s https://api.github.com/repos/trexminer/T-Rex/releases/latest)

# Extract the latest version, URL, and file name from the JSON response
LATEST_VERSION=$(echo $LATEST_RELEASE | jq -r '.tag_name')
LATEST_URL=$(echo $LATEST_RELEASE | jq -r '.assets[] | select(.name | endswith("linux.tar.gz")) | .browser_download_url')
LATEST_FILE_NAME=$(echo $LATEST_RELEASE | jq -r '.assets[] | select(.name | endswith("linux.tar.gz")) | .name')

# Output the latest version, URL, and file name
echo "Latest Version: $LATEST_VERSION"
echo "Latest URL: $LATEST_URL"
echo "Latest File Name: $LATEST_FILE_NAME"

# Define the desktop path and the folder names
DESKTOP_PATH="$HOME/Desktop/trex_miner"
LATEST_FOLDER_NAME=${LATEST_FILE_NAME//.tar.gz/}
LATEST_FOLDER_PATH="$DESKTOP_PATH/$LATEST_FOLDER_NAME"

# Create the folder if it does not exist
if [ ! -d "$DESKTOP_PATH" ]; then
  mkdir -p "$DESKTOP_PATH"
fi

# Verify and extract the latest version to the designated folder
echo "Verifying extraction to: \"$LATEST_FOLDER_PATH\""
if [ -d "$LATEST_FOLDER_PATH" ]; then
  echo "Latest version already downloaded"
else
  # Remove any existing old files and folders
  rm -f "$DESKTOP_PATH"/trex-*-linux.tar.gz
  rm -rf "$DESKTOP_PATH"/trex-*-linux

  # Download the latest version and extract it
  curl -s -L -o "$DESKTOP_PATH/trex.tar.gz" "$LATEST_URL"
  tar -xf "$DESKTOP_PATH/trex.tar.gz" -C "$DESKTOP_PATH"
fi

# Add the execution command for the T-Rex miner with the necessary parameters for mining Conflux
"$DESKTOP_PATH/t-rex" -a octopus -o "$MINING_POOL_ADDRESS" -u "$CONFLUX_WALLET_ADDRESS.$WORKER_NAME" -p x

# Pause for 5 seconds before exiting
sleep 5
