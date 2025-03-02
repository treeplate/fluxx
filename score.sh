#!/bin/bash
if [ `cat debug` == "yes" ]
then
  dart main.dart
else
  declare -A winners
  for seed in {20..40}
  do
    rSLT=`dart main.dart $seed`
    if [ winners[$rSLT] == "" ] 
    then
      winners[$rSLT] = 1
    else 
      winners[$rSLT]=$((winners[$rSLT]+1))
    fi
  done
  for i in "${!winners[@]}"
  do
    echo "${i}=${winners[$i]}"
  done
fi