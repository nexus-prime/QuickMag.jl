#! /bin/bash

# Input 1: URL to host.gz
# Output file path

wget $1 -q -t 4 -o /dev/null -O - | gunzip | grep -E '(credit|id|model|host|coproc|xml)' > $2
