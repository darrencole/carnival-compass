#!/bin/bash

flutter format ./lib

git diff

if [[ $(git diff) ]]; then
    echo "Formatting is incorrect see diff above. Run \"flutter format ./lib\" to correct formatting."
    exit 1
else
    echo "Formatting is good"
fi
