# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk
#exe name
TOPNAME = top
NXDC_FILES = constr/top.nxdc
# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

#build dir verilator_obj_dir and exe path
BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

#verilate_flags
VERILATOR_FLAGS = -Wall --cc -MMD --build

#nvboard flags link flags in nvboard.mk
LDFLAGS +=-lSDL2 -lSDL2_image

#INC_PATH In nvboard.mk
INCFLAGS = $(addprefix -I,$(INC_PATH))

#CFLAGS
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(shell mkdir -p $(BUILD_DIR))


all:
	@echo "Write this Makefile by your self."

sim: $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	#@echo "Write this Makefile by your self."
	verilator $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
	        --Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
clean:
	rm -rf $(BUILD_DIR)
include ../Makefile

$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
