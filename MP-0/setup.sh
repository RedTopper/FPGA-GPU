######################################################################
# Joseph Zambreno
# setup.sh - shell configuration for initial CprE480 lab
######################################################################


# Xilinx and gcc configuration. We should only do this on RHEL machines for now
if [ ! -f /etc/redhat-release ]; then
  return 0
fi


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

