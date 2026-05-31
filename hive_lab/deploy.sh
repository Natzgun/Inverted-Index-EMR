#!/bin/bash

set -e

echo "Initializing terraform..."
terraform init

echo "Building terraform plan..."
terraform plan

echo "Deploying infrastructure..."
terraform apply -auto-approve

echo "Deployment complete"
