######################################################################
# Joseph Zambreno
# setup.sh - shell configuration for CprE480 labs
######################################################################

# Confirm that you have not already run the setup.sh
if [ "$SGP_SETUP" == "1" ]; then
  printf "Error: SGP_SETUP already defined.\n"
  printf "Please open a new terminal to apply new changes, or set the SGP_\n"
  printf "configuration variables directly.\n"
  return 1
fi

export SGP_SETUP="1"

SDIR=`dirname "$BASH_SOURCE"`
export CDIR=`readlink -f "$SDIR"`

# Link-time driver configuration variables. 
# Check the CprE 480 documentation for how to change these. 
export SGP_TRANSMIT="ETH"          # [ETH* | NONE]
export SGP_TRACE="NONE"          # [FILE* | STDOUT | DEEP | VBIOS | NONE]
export SGP_DEST="192.168.1.128"    # [192.168.1.128*]
export SGP_NAME="trace.sgb"        # [trace.sgb* | trace.dat]

alias sgpETH="export SGP_TRANSMIT=ETH;export SGP_DEST=192.168.1.128;"
alias sgpNONE="export SGP_TRANSMIT=NONE;export SGP_TRACE=NONE;"
alias sgpNOLOG="export SGP_TRACE=NONE"
alias sgpLOG="export SGP_TRACE=FILE"
alias sgpPRINT="export SGP_TRACE=STDOUT"
alias sgpSTDOUT="export SGP_TRACE=STDOUT"
alias sgpDEEP="export SGP_TRACE=DEEP"
alias sgpSIM="export SGP_TRACE=VBIOS;export SGP_NAME=trace.dat;"
alias sgpLIST="export | grep SGP"

printf "Adding CprE 480 utils/ and sw/ to your path..."
export PATH=$PATH:$CDIR/utils/bin/:$CDIR/sw/bin/
export LD_LIBRARY_PATH=$CDIR/utils/lib64:$CDIR/utils/lib:$CDIR/sw/common/lib:$LD_LIBRARY_PATH
export TRACE_LIBGL=/lib/x86_64-linux-gnu/libGL.so.1
printf "done.\n"

# Xilinx and gcc configuration. We should only do this on RHEL machines for now
if [ ! -f /etc/redhat-release ]; then
  return 0
fi


export TRACE_LIBGL=/usr/lib64/nvidia/libGL.so.1

export VVDO_VER=2020.1
export ARCH_VER=64

printf "Setting up environment variables for %s-bit Xilinx Vivado tools, version %s..." $ARCH_VER $VVDO_VER
source /remote/Xilinx/$VVDO_VER/Vivado/$VVDO_VER/settings$ARCH_VER.sh
printf "done.\n"

printf "Setting up license file..."
export LM_LICENSE_FILE=1717@io.ece.iastate.edu:27006@io.ece.iastate.edu:27008@io.ece.iastate.edu
printf "done.\n"

printf "Setting up devtools-8 environment..."
#scl enable devtoolset-8 bash
source /opt/rh/devtoolset-8/enable
printf "done.\n"

