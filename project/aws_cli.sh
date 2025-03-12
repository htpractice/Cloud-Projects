#!/bin/bash
#
# Install AWS CLI
#
# Usage: `./aws_cli.sh`
#
# This script will download the latest version of AWS CLI and install it to /usr/local/bin.
# You can run this script directly with the following command:
#
#   bash <(curl -s https://raw.githubusercontent.com/aws/aws-cli/v2/develop/dist/aws_cli.sh)
#
# or
#
#   curl -s https://raw.githubusercontent.com/aws/aws-cli/v2/develop/dist/aws_cli.sh | bash
#
# For more information, see https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
# set -x
curl -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get update
if ! command -v unzip &> /dev/null
then
	sudo apt-get install unzip
else
  echo "System is already up to date."
fi
unzip awscliv2.zip
chmod +x ./aws/install
sudo ./aws/install