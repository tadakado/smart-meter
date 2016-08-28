#!/bin/bash

GPATH=Gerber
Project=SmartMeter
EPATH=Elecrow

rm -r -f $EPATH
mkdir -p $EPATH

for file in ${GPATH}/${Project}* ; do
  fn=`basename $file`
  if [[ $file =~ .drl$ ]] ; then
    cp -a -f $file ${EPATH}/${fn/drl/txt}
  else
    fn=${fn/-*.*./.}
    if [[ $fn =~ .gm1$ ]] ; then
      fn=${fn%.gm1}.gml
    fi
    cp -a -f $file ${EPATH}/$fn
  fi
done
