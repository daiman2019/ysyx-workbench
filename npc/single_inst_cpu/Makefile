# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk
#exe name
TOPNAME = top
NXDC_FILES = constr/top.nxdc

BUILD_DIR = ./build
# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

#build dir verilator_obj_dir and exe path

OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

#verilate_flags
VERILATOR_FLAGS =  --cc -MMD --build --trace \
                  -O3 --x-assign fast --x-initial fast --noassert 
# -Wno-CASEX 禁用casex警告
# --lint-only模式快速验证修改效果，lint静态分析和代码检查工具
#  -Wall打开所有warning
# --Wno-fatal将致命warning降级为普通警告，允许编译继续

#nvboard flags link flags in nvboard.mk
LDFLAGS +=-lSDL2 -lSDL2_image
LDFLAGS +=-lreadline
#LDFLAGS +=-lLLVM-11
#ifdef CONFIG_ITRACE
#CXXSRC = csrc/main.cpp
#CXXFALGS += $(shell llvm-config --cxxflags) -fPIE
#LIBS += $(shell llvm-config-11 --libs)
#endif
#INC_PATH In nvboard.mk
INCFLAGS = $(addprefix -I,$(INC_PATH))

#CFLAGS
CFLAGS += -g $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(shell mkdir -p $(BUILD_DIR))

$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

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

run:sim
	$(BUILD_DIR)/$(TOPNAME) $(ARGS)
	
include ../../Makefile


