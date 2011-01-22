#!/bin/bash

moddir=stivan
baselang=italian
languages="english french spanish"

mkdir traify-tmp 2>/dev/null
for language in $languages; do
  mkdir -p $moddir/tra/$language/decompiled 2>/dev/null
done

for fullpath in `find $moddir -iname *.d -or -iname *.baf -or -iname *.tp* | grep -v $moddir/tra/`; do
  filename=`basename $fullpath`
  extension=${filename##*.}
  tmpbase=${filename%.*}
  if [ $extension = "d" ] || [ $extension = "D" ]; then
    basetra=${filename%.*}
  else
    basetra=setup
  fi
  if [ -f $moddir/tra/$baselang/$basetra.tra ]; then
    weidu --traify $fullpath --out traify-tmp/$filename --traify-old-tra $moddir/tra/$baselang/$basetra.tra
  else
    weidu --traify $fullpath --out traify-tmp/$filename
  fi
  mv traify-tmp/$filename $fullpath
  if [ -s traify-tmp/$tmpbase.tra ]; then
    mv traify-tmp/$tmpbase.tra $moddir/tra/$baselang/$basetra.tra

    for language in $languages $baselang; do
      if grep '@' $fullpath > /dev/null && [ -f $moddir/tra/$language/$basetra.tra ]; then
        weidu --untraify-d $fullpath --untraify-tra $moddir/tra/$language/$basetra.tra --out $moddir/tra/$language/decompiled/$filename
      fi
    done
  else
    rm traify-tmp/$tmpbase.tra
  fi
done
rm -r traify-tmp
