#------------------------------------------------------------------------------
# USER-MODIFIABLE COMPONENT OF MAKEFILE
#
# Note: all paths should be absolute (start with /)
#------------------------------------------------------------------------------
# TODO: Have default installation be CARL/CARLsim
# desired installation path of libcarlsim and headers
CARLSIM_LIB_INSTALL_DIR ?= /opt/CARL/carlsim

# cuda capability major version number
CUDA_MAJOR_NUM ?= 1
# cuda capability minor version number
CUDA_MINOR_NUM ?= 3

# $(OPT_LEVEL): set to 1, 2, or 3 if you want to use optimization.  Default: 0.
# $(DEBUG_INFO): set to 1 to include debug info, set to 0 to not include
# debugging info.  Default: 0.
CARLSIM_CUDAVER ?= 3
CARLSIM_FASTMATH ?= 0
CARLSIM_CUOPTLEVEL ?= 0
CARLSIM_DEBUG ?= 0

#------------------------------------------------------------------------------
# OPTIONAL FEATURES:
#
# Note: These features aren't necessary for a functioning CARLsim installation.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Deprecated: CARLsim/Evolving Objects Parameter Tuning Interface Options
#------------------------------------------------------------------------------
# path of evolving objects installation for EO-PTI CARLsim support (deprecated)
EO_INSTALL_DIR ?= /opt/eo
EO_PTI_INSTALL_DIR ?= /opt/CARL/carlsim_eo_pti

#------------------------------------------------------------------------------
# CARLsim/ECJ Parameter Tuning Interface Options
#------------------------------------------------------------------------------
# path of evolutionary computation in java installation for ECJ-PTI CARLsim
# support
ECJ_INSTALL_DIR ?= /opt/ecj
ECJ_PTI_INSTALL_DIR ?= /opt/CARL/carlsim_ecj_pti

#------------------------------------------------------------------------------
# CARLsim Developer Features: Running tests and compiling from sources
#------------------------------------------------------------------------------


# path of installation of Google test framework
GTEST_DIR ?= /opt/gtest

# whether to include flag for regression testing
CARLSIM_TEST ?= 0

# If this is set to 1, compile from installed CARLsim lib, if 0 compile from
# source. 1 is default. Compiling from source is mainly for devs.
# TODO: I probably won't even need this. If you want to compile from source,
# just use the main Makefile. If you want to compile from the library, just
# use the Makefile in the example/project directory.
# Explain why you need CARLSIM_SRC_DIR
# TODO: explain that testing will always build from src
USE_CARLSIM_SRC ?= 1
CARLSIM_SRC_DIR ?= /home/kris/Project/CARLsim

#------------------------------------------------------------------------------
# END OF USER-MODIFIABLE SECTION
#------------------------------------------------------------------------------

# variable defintions
CXX = g++
NVCC = nvcc
CPPFLAGS = $(DEBUG_FLAG) $(OPT_FLAG) -Wall -std=c++0x

MV := mv -f
RM := rm -rf

# set up CARLSIM/CUDA variables
ifeq (${strip ${CUDA_MAJOR_NUM}},1)
	ifeq (${strip ${CUDA_MINOR_NUM}},2)
		CARLSIM_FLAGS += -arch sm_12 -D__NO_ATOMIC_ADD__
	else
		CARLSIM_FLAGS += -arch sm_13 -D__NO_ATOMIC_ADD__
	endif
else ifeq (${strip ${CUDA_MAJOR_NUM}},2)
	ifeq (${strip ${CUDA_MINOR_NUM}},0)
		CARLSIM_FLAGS += -arch sm_20
	else
		CARLSIM_FLAGS += -arch sm_21
	endif
else ifeq (${strip ${CUDA_MAJOR_NUM}},3)
	ifeq (${strip ${CUDA_MINOR_NUM}},0)
		CARLSIM_FLAGS += -arch sm_30
	else
		CARLSIM_FLAGS += -arch sm_35
	endif
endif

ifeq (${strip ${CARLSIM_CUDAVER}},3)
	CARLSIM_INCLUDES = -I${NVIDIA_SDK}/C/common/inc/
	CARLSIM_LFLAGS = -L${NVIDIA_SDK}/C/lib
	CARLSIM_LIBS = -lcutil_x86_64
	CARLSIM_FLAGS += -D__CUDA3__
else ifeq (${strip ${CARLSIM_CUDAVER}},5)
	CARLSIM_INCLUDES = -I/usr/local/cuda/samples/common/inc/
	CARLSIM_LFLAGS =
	CARLSIM_LIBS =
	CARLSIM_FLAGS += -D__CUDA5__
else ifeq (${strip ${CARLSIM_CUDAVER}},6)
	CARLSIM_INCLUDES = -I/usr/local/cuda/samples/common/inc/
	CARLSIM_LFLAGS =
	CARLSIM_LIBS =
	CARLSIM_FLAGS += -D__CUDA6__
endif

# use fast math
ifeq (${strip ${CARLSIM_FASTMATH}},1)
	CARLSIM_FLAGS += -use_fast_math
endif

# use CUDA optimization level
ifneq (${strip ${CARLSIM_CUOPTLEVEL}},1)
	CARLSIM_FLAGS += -O${CARLSIM_CUOPTLEVEL}
endif

# set debug flag
ifeq (${strip ${CARLSIM_DEBUG}},1)
	CARLSIM_FLAGS += -g
endif

# set regression flag
ifeq (${strip ${CARLSIM_TEST}},1)
	CARLSIM_FLAGS += -I$(CURDIR)/$(test_dir) -D__REGRESSION_TESTING__
# if you are testing, you must compile from src
	USE_CARLSIM_SRC = 1
endif

# set flags for compiling from CARLsim src or lib
ifeq (${USE_CARLSIM_SRC},0)
# carlsim components
	kernel_dir     = $(CARLSIM_LIB_INSTALL_DIR)/kernel
	interface_dir  = $(CARLSIM_LIB_INSTALL_DIR)/interface
	spike_mon_dir  = $(CARLSIM_LIB_INSTALL_DIR)/spike_monitor
	spike_gen_dir  = $(CARLSIM_LIB_INSTALL_DIR)/spike_generators
# we are compiling from lib
	CARLSIM_FLAGS += -I$(CARLSIM_LIB_INSTALL_DIR)/include/kernel \
									 -I$(CARLSIM_LIB_INSTALL_DIR)/include/interface \
									 -I$(CARLSIM_LIB_INSTALL_DIR)/include/spike_monitor \
									 $(CARLSIM_LIB_INSTALL_DIR)/lib/libCARLsim.a
else
# carlsim components
	kernel_dir     = $(CARLSIM_SRC_DIR)/carlsim/kernel
	interface_dir  = $(CARLSIM_SRC_DIR)/carlsim/interface
	spike_mon_dir  = $(CARLSIM_SRC_DIR)/carlsim/spike_monitor
	spike_gen_dir  = $(CARLSIM_SRC_DIR)/tools/carlsim_addons/spike_generators
# we are compiling from src
	CARLSIM_FLAGS += -I$(kernel_dir)/include -I$(interface_dir)/include -I$(spike_mon_dir)
endif

# location of .h files
vpath %.h $(EO_INSTALL_DIR)/src $(kernel_dir)/include \
$(ex_dir)/common $(interface_dir)/include $(spike_mon_dir) $(test_dir)

# location of .cpp files
vpath %.cpp $(kernel_dir)/src $(interface_dir)/src $(test_dir) \
$(spike_info_dir) $(ex_dir)/common/

# location of .cu files
vpath %.cu $(kernel_dir)/src $(test_dir)
