SHELL := /bin/bash
# target and root file name
TARGET = coaching-journal

# Directories
TEXMF_DIR = texmf
SOURCE_DIR = journal
BUILD_DIR = build

# an directory containing images unser $SOURCE_DIR
IMAGES_DIR = images

# An environment variable for kpsewhich search path
TEXMF_VARIABLE = TEXMFLOCAL

# commands to compile document
LATEX = xelatex --shell-escape -halt-on-error

# source files
TEX_FILES = $(wildcard $(SOURCE_DIR)/*.tex)
SVG_FILES = $(wildcard $(SOURCE_DIR)/$(IMAGES_DIR)/*.svg)
IMAGE_FILES = $(wildcard $(SOURCE_DIR)/$(IMAGES_DIR)/*.png) \
              $(wildcard $(SOURCE_DIR)/$(IMAGES_DIR)/*.pdf) \
              $(wildcard $(SOURCE_DIR)/$(IMAGES_DIR)/*.eps) \
              $(wildcard $(SOURCE_DIR)/$(IMAGES_DIR)/*.jpg) \
              $(wildcard $(SOURCE_DIR)/$(IMAGES_DIR)/*.jpeg)

# generated files
LINKED_IMAGE_FILES = $(addprefix $(BUILD_DIR)/$(IMAGES_DIR)/,$(notdir $(IMAGE_FILES)))
EPS_FILES = $(addprefix $(BUILD_DIR)/$(IMAGES_DIR)/,$(notdir $(SVG_FILES:%.svg=%.pdf)))
LINKED_TEX_FILES = $(addprefix $(BUILD_DIR)/,$(notdir $(TEX_FILES)))

# Full path of texmf dir
FULL_TEXMF_DIR = $(shell realpath $(TEXMF_DIR))
ROOT_DIR = $(shell realpath .)

.DEFAULT_GOAL = pdf

$(TEXMF_DIR)/ls-R : $(TEXMF_DIR)
	mktexlsr $(TEXMF_DIR)

.PHONY : pdf
pdf : $(BUILD_DIR)/$(TARGET).pdf
$(BUILD_DIR)/$(TARGET).pdf : $(BUILD_DIR)/$(TARGET).dvi $(TEX_FILES) $(EPS_FILES)
	cd $(BUILD_DIR) && \
	$(TEXMF_VARIABLE)=$(FULL_TEXMF_DIR) $(LATEX) $(TARGET) && \
	cp $(TARGET).pdf $(ROOT_DIR)

$(BUILD_DIR)/$(TARGET).dvi : $(BUILD_DIR)/$(TARGET).bbl $(BUILD_DIR)/$(TARGET).aux
	cd $(BUILD_DIR) && \
	$(TEXMF_VARIABLE)=$(FULL_TEXMF_DIR) $(LATEX) $(TARGET) && \
	$(TEXMF_VARIABLE)=$(FULL_TEXMF_DIR) $(LATEX) $(TARGET) >/dev/null

$(BUILD_DIR)/$(TARGET).bbl : $(BUILD_DIR)/$(TARGET).aux $(LINKED_BIB_FILES)
ifneq ($(strip $(BIB_FILES)),)
	cd $(BUILD_DIR) && \
	$(TEXMF_VARIABLE)=$(FULL_TEXMF_DIR) $(BIBTEX) $(TARGET)
endif

$(BUILD_DIR)/$(TARGET).aux : $(BUILD_DIR)/ $(LINKED_TEX_FILES) $(LINKED_IMAGE_FILES) $(TEX_FILES) $(EPS_FILES) $(TEXMF_DIR)/ls-R
	cd $(BUILD_DIR) && \
	$(TEXMF_VARIABLE)=$(FULL_TEXMF_DIR) $(LATEX) $(TARGET)

$(BUILD_DIR)/ :
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/$(IMAGES_DIR)/ :
	mkdir -p $(BUILD_DIR)/$(IMAGES_DIR)

$(BUILD_DIR)/% : $(SOURCE_DIR)/% $(BUILD_DIR)/
	ln -fs $(shell realpath "$<") "$@"

$(BUILD_DIR)/$(IMAGES_DIR)/% : $(SOURCE_DIR)/$(IMAGES_DIR)/% $(BUILD_DIR)/$(IMAGES_DIR)/
	ln -fs $(shell realpath "$<") "$@"

$(BUILD_DIR)/$(IMAGES_DIR)/%.pdf : $(SOURCE_DIR)/$(IMAGES_DIR)/%.svg $(BUILD_DIR)/$(IMAGES_DIR)/
	inkscape -z -D --file="$<" --export-pdf="$@"

.PHONY : clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(TEXMF_DIR)/ls-R

.PHONY : help
help:
	@echo "make pdf"
	@echo "        Make PDF file from DVI file."
	@echo "make clean"
	@echo "        Clean build directory."
