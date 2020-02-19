#!/bin/bash

print_info () {
  echo -e "\e[32m${1}\e[0m"
}

print_error () {
  echo -e "\e[31mERROR: ${1}\e[0m"

  # Clean up and exit
  if [ "$VIRTUAL_ENV" != "" ]; then
    my_venvs_deactivate
  fi
  exit
}

print_time () {
  if [ "$1" == "" ]; then
    echo -e "\e[33mCurrent time: `date`\e[0m"
  else
    TIME_NOW=`date +%s`
    TIME_ELAPSE=`echo "$TIME_NOW - $1" | bc`
    echo -e "\e[33mTime elapsed: ${TIME_ELAPSE}s\e[0m"
  fi
}

ENV_NAME=astro-iv-env
KERNEL_NAME=py3_astro_iv
KERNEL_DISP="Astro-IV"

PKGS=(astropy mpi4py toolz nbodykit emcee corner)

GSL_URL=ftp://ftp.gnu.org/gnu/gsl/gsl-2.6.tar.gz


# Initilise the bash environment
BASH_FUNCTIONS=~/.bash_functions
for f in $(find $BASH_FUNCTIONS -type f -name '*\.sh'| sort); do source $f; done

TIME_START=`date +%s`
print_time


# Setup virtual environment

ENV_DIR=${MY_VENVS}/${ENV_NAME}
if [ -d "$ENV_DIR" ]; then
  print_info "Loading existing virtual environment $ENV_NAME ..."
  my_venvs_activate $ENV_NAME || print_error "cannot load virtual environment: $ENV_NAME"

  print_info "Checking installed packages ..."
  PIP_INSTALLED=`pip list --local --format=legacy`
else
  print_info "Creating virtual environment $ENV_NAME ..."

  my_venvs_create $ENV_NAME || print_error "cannot create virtual environment: $ENV_NAME"
  my_venvs_activate $ENV_NAME || print_error "cannot load virtual environment: $ENV_NAME"
  PIP_INSTALLED=""
fi

print_time $TIME_START


# Check if GSL exists (required by nbodykit/Corrfunc)

GSL_LIB=${VIRTUAL_ENV}/lib/libgsl.so
if [ ! -f "$GSL_LIB" ]; then
  print_info "Installing GSL ..."

  print_info "  Fetching the source code ..."
  SRC_DIR=${VIRTUAL_ENV}/src
  if [ ! -d "$SRC_DIR" ]; then
    mkdir "$SRC_DIR"
  fi
  cd "$SRC_DIR" || print_error "cannot access the directory for GSL source files: $SRC_DIR"

  GSL_TAR=`basename $GSL_URL`
  if [ "${GSL_TAR:(-7)}" != ".tar.gz" ]; then
    print_error "unrecognised file extension for GSL source code: $GSL_URL"
  fi
  if [ ! -f "$GSL_TAR" ]; then
    wget "$GSL_URL" || print_error "cannot fetch GSL source code: $GSL_URL"
  fi

  print_info "  Untaring the GSL source code ..."
  GSL_SRC=${SRC_DIR}/${GSL_TAR::(-7)}
  tar zxf "$GSL_TAR" || print_error "cannot retreive the GSL source code: $GSL_TAR"
  cd "$GSL_SRC" || print_error "cannot find the retrieved GSL source code: $GSL_SRC"
  print_time $TIME_START

  print_info "  Compiling GSL ..."
  ./configure --prefix="${VIRTUAL_ENV}" || print_error "cannot configure GSL"
  make || print_error "cannot compile the GSL source code"
  make install || print_error "cannot install GSL"

  print_time $TIME_START
fi


# Install python packages

for PKG in ${PKGS[@]}; do
  PKG_EXIST=`echo "$PIP_INSTALLED" | grep -c "^${PKG} ("`
  if [ "$PKG_EXIST" == 0 ]; then
    print_info "Installing python package $PKG ..."
    pip install $PKG
    print_time $TIME_START
  fi
done


# Build jupyter kernel

KERNEL_EXIST=`jupyter kernelspec list | grep -c " ${KERNEL_NAME} "`
if [ "$KERNEL_EXIST" == 0 ]; then
  print_info "Building jupyter kernel ..."
  my_kernels_create "$KERNEL_NAME" "$KERNEL_DISP" || print_error "cannot build jupyter kernel"

  print_time $TIME_START
fi

my_venvs_deactivate

print_info "Done with setting up the jupyter environment for Astro-IV!"
print_time $TIME_START

