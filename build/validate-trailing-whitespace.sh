#!/bin/bash

grep -rno --exclude-dir=.git '[[:blank:]]$' .

# Check the exit code
if [ $? -eq 0 ]; then
  echo "Correct files that contain files with whitespace"
  exit 1
fi
