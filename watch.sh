#!/bin/bash

echo chromeless.swift | entr -r bash -c '
  clear
  swiftc -o chromeless chromeless.swift -framework Cocoa 2> compile_errors.txt
  if [ $? -ne 0 ]; then
    cat compile_errors.txt
    cat compile_errors.txt | pbcopy
    exit 1
  fi
  pkill -f ./chromeless || true
  if [ -x chromeless ]; then
    ./chromeless &
  fi
'
