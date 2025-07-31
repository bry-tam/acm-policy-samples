#!/bin/bash

eCode=0

for kst in `find . -name "*.y*ml"`; do
  line_one=`head -n 1 $kst`

  if [ "$line_one" != "---" ]; then
    echo "Missing start: ${kst}"
    #sed -i '1s/^/---\n/' ${kst}
    eCode=1
  fi
done

exit $eCode
