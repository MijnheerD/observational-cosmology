#!/bin/bash
# This script downloads the exercise jupyter notebooks.
# Just put all the ones you want to download into the NOTEBOOKS array.

ROOT_URL="https://obswww.unige.ch/~ivkovic/homepage/astro-iv"
NOTEBOOKS=(setup hubble_law)

if [ "$ROOT_URL" == "" ]; then
  echo "Error: ROOT_URL not set!"
  exit
fi

source ${HOME}/jnb.conf
if [ "$MY_NOTEBOOKS" == "" ]; then
  MY_NOTEBOOKS=${HOME}/my_notebooks
fi

cd $MY_NOTEBOOKS

for NB in ${NOTEBOOKS[@]}; do
  URL=${ROOT_URL}/E_jupyter_${NB}.ipynb
  wget $URL
done

