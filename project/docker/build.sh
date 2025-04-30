#!/bin/bash

# Define the list of arguments
REGION="$1"
AWS_ACCOUNT_ID="$2"
AWS_REPO_NAMES=("$3" "$4")

# Build the Docker image with the arguments
docker build --build-arg REGION=$REGION --build-arg AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID --build-arg AWS_REPO_NAMES="${AWS_REPO_NAMES[*]}" -t jenkins-docker:latest .