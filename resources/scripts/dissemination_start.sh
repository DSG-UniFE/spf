#!/bin/bash

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ] ; then
    echo "Illegal number of parameters"
    exit 1
fi

dirname = `dirname "$1"`
cd $dirname
if [ "$#" -eq 1 ] ; then
  $1
else
  $1 -c $2
fi

exit 0
