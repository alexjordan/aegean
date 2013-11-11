TCREST_TOOL_PATH?=$(CURDIR)/../local/bin
PATH:=$(PATH):$(TCREST_TOOL_PATH)

AEGEAN_PATH?=$(CURDIR)
#AEGEAN_PLATFORM?=Test_platform.xml
AEGEAN_PLATFORM?=mandelbrot_demo
AEGEAN_PLATFORM_FILE=$(AEGEAN_PATH)/config/$(AEGEAN_PLATFORM).xml

BUILD_PATH?=$(AEGEAN_PATH)/build/$(AEGEAN_PLATFORM)

AEGEAN_SRC_PATH?=$(AEGEAN_PATH)/VHDL
AEGEAN_SRC=$(patsubst %,$(BUILD_PATH)/%,\
	noc.vhd aegean.vhd)
AEGEAN_CONFIG_SRC=$(patsubst %,$(BUILD_PATH)/%,\
	config.vhd)
TEST_SRC=$(patsubst %,$(AEGEAN_SRC_PATH)/%,\
	packages/test.vhd)
TESTBENCH_SRC=$(patsubst %,$(BUILD_PATH)/%,\
	aegean_testbench.vhd)

POSEIDON_PATH?=$(CURDIR)/../poseidon
POSEIDON?=$(POSEIDON_PATH)/build/Poseidon
POSEIDON_CONV=java -cp $(POSEIDON_PATH)/Converter/build/ converter.Converter


PATMOS_PATH?=$(CURDIR)/../patmos
PATMOS_SOURCE?=$(BUILD_PATH)/*.v
PATMOS_BOOTAPP?=bootable-mandelbrot_par

ARGO_PATH?=$(CURDIR)/../t-crest-noc
ARGO_SRC_PATH?=$(ARGO_PATH)/noc/src
ARGO_SRC=$(patsubst %,$(ARGO_SRC_PATH)/%,\
	noc_defs.vhd noc_interface.vhd bram.vhd bram_tdp.vhd counter.vhd\
	dma.vhd nAdapter.vhd hpu.vhd xbar.vhd router.vhd com_spm.vhd noc_node.vhd)
CONFIG_SRC=$(patsubst %,$(ARGO_SRC_PATH)/%,\
	ocp.vhd)


SIM_PATH?=$(AEGEAN_SRC_PATH)/sim
SYNTH_PATH=$(BUILD_PATH)/quartus
VLIB=vlib -quiet work
VCOM=vcom -quiet -93 -work $(BUILD_PATH)/work
VLOG=vlog -quiet -work $(BUILD_PATH)/work
VSIM=vsim -novopt -lib $(BUILD_PATH)/work

ifeq ($(WINDIR),)
	S=:
else
	S=\;
endif

# Use Wine on OSX
# I would like to use a better way, but some shell variables
# are not set within make.... Don't know why...
ifeq ($(TERM_PROGRAM),Apple_Terminal)
	WINE=wine
else
	WINE=
endif

.PHONY: sim synth config platform compile
.FORCE:

all: sim

#########################################################################
# Generation of source code for the platform described in AEGEAN_PLATFORM
# Call make platform
#########################################################################
platform: $(AEGEAN_PLATFORM_FILE) $(BUILD_PATH)
	python3 $(AEGEAN_PATH)/python/main.py $(AEGEAN_PLATFORM_FILE)

$(BUILD_PATH):
	mkdir -p $(BUILD_PATH)/quartus
	mkdir -p $(BUILD_PATH)/xml
	-cp $(AEGEAN_PATH)/quartus/aegean_top.cdf $(BUILD_PATH)/quartus/$(AEGEAN_PLATFORM)_top.cdf
	-cp $(AEGEAN_PATH)/quartus/aegean_top.qpf $(BUILD_PATH)/quartus/$(AEGEAN_PLATFORM)_top.qpf
	-cp $(AEGEAN_PATH)/quartus/aegean_top.qsf $(BUILD_PATH)/quartus/$(AEGEAN_PLATFORM)_top.qsf
	-cp $(AEGEAN_PATH)/quartus/aegean_top.sdc $(BUILD_PATH)/quartus/$(AEGEAN_PLATFORM)_top.sdc

#schedule: $(BUILD_PATH)/init.h

#$(BUILD_PATH)/init.h: $(BUILD_PATH)/sched.xml
#	$(POSEIDON_CONV) $< $@ Aegean-c

#$(BUILD_PATH)/aegean_sched.xml: $(AEGEAN_PATH)/config/bitorus2x2.xml
#	mkdir -p $(BUILD_PATH)
#	$(POSEIDON) -m GREEDY -p $< -s $@

#$(PATMOS_PATH)/c/init.h: $(BUILD_PATH)/init.h
#	cp $< $@

##########################################################################
# Compilation of source code for the platform described in AEGEAN_PLATFORM
# Call make compile
##########################################################################
compile: $(BUILD_PATH)/work compile-config compile-patmos compile-argo $(AEGEAN_SRC)
	$(WINE) $(VCOM) $(AEGEAN_SRC)

$(BUILD_PATH)/work:
	mkdir -p $(BUILD_PATH)
	cd $(BUILD_PATH) && $(WINE) $(VLIB)

compile-argo: $(BUILD_PATH)/work compile-config $(ARGO_SRC)
	$(WINE) $(VCOM) $(ARGO_SRC)

#$(PATMOS_SOURCE): $(PATMOS_PATH)/c/init.h .FORCE
#	make -C $(PATMOS_PATH) BOOTAPP=$(PATMOS_BOOTAPP) BOOTBUILDDIR=$(BUILD_PATH) CHISELBUILDDIR=$(BUILD_PATH) gen

compile-patmos: $(BUILD_PATH)/work $(PATMOS_SOURCE)
	$(WINE) $(VLOG) $(PATMOS_SOURCE)

compile-config: $(BUILD_PATH)/work $(AEGEAN_CONFIG_SRC) $(CONFIG_SRC)
	$(WINE) $(VCOM) $(AEGEAN_CONFIG_SRC)
	$(WINE) $(VCOM) $(CONFIG_SRC)

#########################################################################
# Simulation of source code for the platform described in AEGEAN_PLATFORM
# Call make sim
#########################################################################
sim: compile $(BUILD_PATH)/work compile $(TEST_SRC) $(TESTBENCH_SRC)
	$(WINE) $(VCOM) $(TEST_SRC) $(TESTBENCH_SRC)
	$(WINE) $(VSIM) -do $(SIM_PATH)/aegean.do aegean_testbench

synth: $(PATMOS_SOURCE) $(CONFIG_SRC) $(ARGO_SRC) $(AEGEAN_SRC)
	quartus_map $(SYNTH_PATH)/$(AEGEAN_PLATFORM)_top
	quartus_fit $(SYNTH_PATH)/$(AEGEAN_PLATFORM)_top
	quartus_asm $(SYNTH_PATH)/$(AEGEAN_PLATFORM)_top
	quartus_sta $(SYNTH_PATH)/$(AEGEAN_PLATFORM)_top

config:
	quartus_pgm -c USB-Blaster -m JTAG $(SYNTH_PATH)/$(AEGEAN_PLATFORM)_top.cdf


update_hw: update_argo update_patmos

update_patmos:
	cd .. && ./misc/build.sh -u patmos

update_argo:
	cd $(ARGO_PATH) && git pull


clean:
	-rm -r $(BUILD_PATH)

help:
	@echo "================================================================================"
	@echo "== This is the help target of the Aegean main Makefile."
	@echo "=="
	@echo "== Targets:"
	@echo "==     all        : Builds all that is needed to simulate thedescribed platform."
	@echo "=="
	@echo "==     platform   : Generates the source files for the platform described"
	@echo "==                  in AEGEAN_PLATFORM file."
	@echo "=="
	@echo "==     compile    : Compiles the full platform."
	@echo "=="
	@echo "==     sim        : Starts the simulation of the platform."
	@echo "=="
	@echo "==     synth      : Synthesises the platform."
	@echo "=="
	@echo "==     update_hw  : Updates the hardware repos."
	@echo "=="
	@echo "==     clean      : Cleans the build directory."
	@echo "=="
	@echo "================================================================================"
