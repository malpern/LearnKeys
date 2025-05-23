#!/bin/bash

# ⚠️  DEPRECATED - This script is for PROTOTYPE development only
# 
# This script watches and compiles the ARCHIVED prototype in prototypes/chromeless.swift
# 
# FOR CURRENT DEVELOPMENT: Use ./lk [config.kbd]
# FOR MANUAL BUILDING: Use LearnKeys/build.sh
#
# This script is kept for reference but should NOT be used for active development.

echo "⚠️  WARNING: This script compiles the DEPRECATED prototype!"
echo "   For current development, use: ./lk [config.kbd]"
echo "   This script will be removed in a future version."
echo "   Press Ctrl+C to cancel, or wait 10 seconds to continue with prototype..."
sleep 10

echo prototypes/chromeless.swift | entr -r bash -c '
  clear
  echo "🔨 Compiling DEPRECATED prototype (not for production use)..."
  swiftc -o prototypes/chromeless prototypes/chromeless.swift -framework Cocoa 2> compile_errors.txt
  if [ $? -ne 0 ]; then
    echo "❌ Compilation failed:"
    cat compile_errors.txt
    cat compile_errors.txt | pbcopy
    exit 1
  fi
  pkill -f ./prototypes/chromeless || true
  if [ -x prototypes/chromeless ]; then
    echo "🚀 Running DEPRECATED prototype..."
    ./prototypes/chromeless &
  fi
'
