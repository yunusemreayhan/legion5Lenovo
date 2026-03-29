#!/bin/bash

echo "Applying Compiz fix for AMD GPU..."

sudo sh -c 'echo "export AMD_DEBUG=nodcc" > /etc/profile.d/amd_fix.sh'
source /etc/profile.d/amd_fix.sh

echo "Compiz fix applied. Please re-login or run: source /etc/profile.d/amd_fix.sh"
