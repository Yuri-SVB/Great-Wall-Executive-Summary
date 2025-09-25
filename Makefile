# Makefile for Great Wall Protocol Executive Summary
# Professional LaTeX document build system following clean room principles

# =============================================================================
# CONFIGURATION
# =============================================================================

# Document settings
MAIN_DOC = main
TEX_ENGINE = pdflatex
BIB_ENGINE = biber

# Directories
BUILD_DIR = build
SECTIONS_DIR = sections
CONFIG_DIR = config
MACROS_DIR = macros
FIGURES_DIR = figures
REFERENCES_DIR = references

# Build options
LATEX_OPTS = -interaction=nonstopmode -halt-on-error -file-line-error
LATEX_OPTS += -output-directory=$(BUILD_DIR)

# Quality assurance tools
LINTER = chktex
SPELL_CHECK = aspell
STYLE_CHECK = lacheck

# =============================================================================
# DEFAULT TARGET
# =============================================================================

.PHONY: all
all: build

# =============================================================================
# BUILD TARGETS
# =============================================================================

.PHONY: build
build: setup $(BUILD_DIR)/$(MAIN_DOC).pdf

.PHONY: setup
setup:
	@echo "Setting up build environment..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(FIGURES_DIR)
	@mkdir -p tables

$(BUILD_DIR)/$(MAIN_DOC).pdf: $(MAIN_DOC).tex $(wildcard $(SECTIONS_DIR)/*.tex) $(wildcard $(CONFIG_DIR)/*.tex) $(wildcard $(MACROS_DIR)/*.tex) $(REFERENCES_DIR)/bibliography.bib
	@echo "Building LaTeX document..."
	$(TEX_ENGINE) $(LATEX_OPTS) $(MAIN_DOC).tex
	@echo "Processing bibliography..."
	cd $(BUILD_DIR) && $(BIB_ENGINE) $(MAIN_DOC)
	@echo "Final compilation passes..."
	$(TEX_ENGINE) $(LATEX_OPTS) $(MAIN_DOC).tex
	$(TEX_ENGINE) $(LATEX_OPTS) $(MAIN_DOC).tex
	@echo "Build complete: $(BUILD_DIR)/$(MAIN_DOC).pdf"

# =============================================================================
# QUALITY ASSURANCE TARGETS  
# =============================================================================

.PHONY: lint
lint:
	@echo "Running LaTeX linting..."
	@if command -v $(LINTER) >/dev/null 2>&1; then \
		$(LINTER) $(MAIN_DOC).tex $(SECTIONS_DIR)/*.tex; \
	else \
		echo "Warning: $(LINTER) not installed. Skipping lint check."; \
	fi

.PHONY: style-check
style-check:
	@echo "Running style check..."
	@if command -v $(STYLE_CHECK) >/dev/null 2>&1; then \
		$(STYLE_CHECK) $(MAIN_DOC).tex; \
	else \
		echo "Warning: $(STYLE_CHECK) not installed. Skipping style check."; \
	fi

.PHONY: spell-check
spell-check:
	@echo "Running spell check..."
	@if command -v $(SPELL_CHECK) >/dev/null 2>&1; then \
		$(SPELL_CHECK) --mode=tex --lang=en --personal=./aspell.en.pws list < $(MAIN_DOC).tex; \
	else \
		echo "Warning: $(SPELL_CHECK) not installed. Skipping spell check."; \
	fi

.PHONY: validate
validate: lint style-check
	@echo "Document validation complete."

# =============================================================================
# DEVELOPMENT TARGETS
# =============================================================================

.PHONY: watch
watch:
	@echo "Starting watch mode (requires entr or inotify-tools)..."
	@if command -v entr >/dev/null 2>&1; then \
		find . -name "*.tex" -o -name "*.bib" | entr -c make build; \
	elif command -v inotifywait >/dev/null 2>&1; then \
		while inotifywait -e modify -r . --include=".*\.(tex|bib)$$"; do make build; done; \
	else \
		echo "Error: Neither entr nor inotifywait found. Install one for watch mode."; \
		exit 1; \
	fi

.PHONY: quick
quick: setup
	@echo "Quick build (single pass)..."
	$(TEX_ENGINE) $(LATEX_OPTS) $(MAIN_DOC).tex

.PHONY: draft
draft: setup
	@echo "Building draft version..."
	$(TEX_ENGINE) $(LATEX_OPTS) -jobname=$(MAIN_DOC)-draft "\def\draftmode{}\input{$(MAIN_DOC).tex}"

# =============================================================================
# CLEANUP TARGETS
# =============================================================================

.PHONY: clean
clean:
	@echo "Cleaning build files..."
	@rm -rf $(BUILD_DIR)/*
	@find . -name "*.aux" -delete
	@find . -name "*.log" -delete
	@find . -name "*.bbl" -delete
	@find . -name "*.blg" -delete
	@find . -name "*.toc" -delete
	@find . -name "*.lof" -delete
	@find . -name "*.lot" -delete
	@find . -name "*.out" -delete
	@find . -name "*.fdb_latexmk" -delete
	@find . -name "*.fls" -delete
	@find . -name "*.synctex.gz" -delete

.PHONY: clean-all
clean-all: clean
	@echo "Deep cleaning..."
	@rm -rf $(BUILD_DIR)

# =============================================================================
# UTILITY TARGETS
# =============================================================================

.PHONY: word-count
word-count:
	@echo "Counting words..."
	@if command -v texcount >/dev/null 2>&1; then \
		texcount -total -brief $(MAIN_DOC).tex; \
	else \
		echo "Warning: texcount not installed. Using basic word count."; \
		detex $(MAIN_DOC).tex | wc -w; \
	fi

.PHONY: check-deps
check-deps:
	@echo "Checking LaTeX dependencies..."
	@command -v $(TEX_ENGINE) >/dev/null 2>&1 || { echo "Error: $(TEX_ENGINE) not found"; exit 1; }
	@command -v $(BIB_ENGINE) >/dev/null 2>&1 || { echo "Error: $(BIB_ENGINE) not found"; exit 1; }
	@echo "Core dependencies satisfied."

.PHONY: open
open: $(BUILD_DIR)/$(MAIN_DOC).pdf
	@echo "Opening PDF..."
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open $(BUILD_DIR)/$(MAIN_DOC).pdf; \
	elif command -v open >/dev/null 2>&1; then \
		open $(BUILD_DIR)/$(MAIN_DOC).pdf; \
	else \
		echo "PDF ready at: $(BUILD_DIR)/$(MAIN_DOC).pdf"; \
	fi

# =============================================================================
# HELP TARGET
# =============================================================================

.PHONY: help
help:
	@echo "Great Wall Protocol Executive Summary - Build System"
	@echo "=================================================="
	@echo ""
	@echo "Build Targets:"
	@echo "  all          - Build complete document (default)"
	@echo "  build        - Build complete document with bibliography"
	@echo "  quick        - Quick single-pass build"
	@echo "  draft        - Build draft version"
	@echo ""
	@echo "Quality Assurance:"
	@echo "  validate     - Run linting and style checks"
	@echo "  lint         - Run LaTeX linting (chktex)"
	@echo "  style-check  - Run style check (lacheck)"
	@echo "  spell-check  - Run spell check (aspell)"
	@echo ""
	@echo "Development:"
	@echo "  watch        - Watch for changes and rebuild"
	@echo "  word-count   - Count words in document"
	@echo "  open         - Open generated PDF"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-all    - Deep clean including build directory"
	@echo "  check-deps   - Check required dependencies"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Usage: make [target]"