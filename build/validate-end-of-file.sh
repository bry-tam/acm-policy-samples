#!/bin/sh

eCode=0
STAGED_FILES=$(find . -path ./.git -prune -false -o -type f -print)

for FILE in $(find . -path ./.git -prune -false -o -type f -print); do
  # Check if the file is a regular file and not a symlink
  if [ -f "$FILE" ] && [ ! -L "$FILE" ]; then
    # Check if the file ends with a newline
    if [ "$(tail -c 1 "$FILE")" != '' ]; then
      echo "Error: File does not end with a newline: '$FILE'"
      eCode=1
    fi
  fi
done

exit $eCode
