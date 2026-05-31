#!/bin/bash

set -e

echo "Destroying infrastructure..."
terraform destroy -auto-approve

echo "Infrastructure destroyed"
