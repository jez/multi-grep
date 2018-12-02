# ============================================================================
#
#   This file was generated with 'symbol-new multi-grep'
#   Do NOT delete this file!
#   This file should be checked into version control.
#
#   For usage information, run
#
#       ./symbol help
#
#   or visit https://symbol.sh
#
# ============================================================================


# You can override any of these settings at the command line with 'var=value'.
# For example, to pass flags to MLton when compiling:
#
#     ./symbol make with=mlton MLTONFLAGS="-profile alloc"
#
# Do NOT edit this file manually.

target := multi-grep
version := v0.10.1
prefix := $(HOME)/.local
main := Main.main

SML := sml
MLTON := mlton
MLTONFLAGS :=


# ----- Public targets --------------------------------------------------------

make: .symbol-work/bin/$(target)
	./symbol log success "$<" >&3

install: $(prefix)/bin/$(target)
	./symbol log success "$<" >&3

.PHONY: version
version:
	@echo $(version)

.PHONY: clean
clean:
	rm -rf .symbol-work .cm src/.cm *.du *.ud


# ----- Internal targets ------------------------------------------------------

# If any part of a pipe fails, the whole command fails
SHELL := $(SHELL) -o pipefail

# Get the platform-specific heap image suffix from SML/NJ
ifeq ($(with),smlnj)
SUFFIX := $(shell $(SML) @SMLsuffix)
endif

# ----- for make -----

ifeq ($(with),smlnj)
.symbol-work/bin/$(target): \
		.symbol-work/smlnj/$(target).$(SUFFIX) \
		.symbol-work/smlnj/$(target)-wrapper.sh
	./symbol log info "Building '$(target)' into '$(@D)'..." >&3
	mkdir -p "$(@D)"
	sed -e 's+HEAP_IMAGE+$(realpath $<)+' .symbol-work/smlnj/$(target)-wrapper.sh > "$@"
	chmod +x "$@"
	echo "$(with)" > .symbol-work/with
endif

ifeq ($(with),mlton)
.symbol-work/bin/$(target): \
		.symbol-work/mlton/$(target)
	./symbol log info "Building '$(target)' into '$(@D)'..." >&3
	mkdir -p "$(@D)"
	cp "$<" "$@"
	echo "$(with)" > .symbol-work/with
endif

# ----- for install -----

# We've made the install target phony so that an install always copy files
# (because they might have switched installed already with a different 'with')
.PHONY: $(prefix)/bin/$(target)
ifeq ($(with),smlnj)
$(prefix)/bin/$(target): \
		$(prefix)/lib/$(target)/$(target).$(SUFFIX) \
		.symbol-work/smlnj/$(target)-wrapper.sh
	./symbol log info "Building '$(target)' into '$(@D)'..." >&3
	mkdir -p "$(@D)"
	sed -e 's+HEAP_IMAGE+$(realpath $<)+' .symbol-work/smlnj/$(target)-wrapper.sh > "$@"
	chmod +x "$@"
endif

ifeq ($(with),mlton)
$(prefix)/bin/$(target): \
		.symbol-work/mlton/$(target)
	./symbol log info "Building '$(target)' into '$(@D)'..." >&3
	mkdir -p "$(@D)"
	cp "$<" "$@"
endif

$(prefix)/lib/$(target)/$(target).$(SUFFIX): .symbol-work/smlnj/$(target).$(SUFFIX)
	mkdir -p "$(@D)"
	cp "$<" "$@"

# ----- smlnj -----

ifeq ($(with),smlnj)
# Given a CM file, builds a makefile that records which source files could
# cause the heap image to become out of date if they changed.
#
# Uses the ml-makedepend tool (see the CM user manual).
#
# The resulting makefile is conditionally included below, so it will take
# effect after the first build.
#
# We remove the file if the build step failed, so that Make doesn't think
# we succeeded and never re-run us.
.symbol-work/smlnj/$(target).cm.mk: $(target).cm
	./symbol log info "Analyzing CM dependencies..." >&3
	mkdir -p "$(@D)"
	touch "$@"
	ml-makedepend -n -f "$@" "$<" '.symbol-work/smlnj/$(target).$(SUFFIX)' || rm -f "$@"

# Only include the makefile once it's been built
-include .symbol-work/smlnj/$(target).cm.mk
endif

# Build an SML/NJ heap image.
#
# Uses ml-build, which build as CM project that exports a function suitable for
# calling SMLofNJ.exportFn on to build a heap image.
.symbol-work/smlnj/$(target).$(SUFFIX): .symbol-work/smlnj/$(target).cm.mk
	./symbol log info "Building heap image with SML/NJ..." >&3
	mkdir -p "$(@D)"
	ml-build \
		"$(target).cm" \
		$(main) \
		".symbol-work/smlnj/$(target)" | tee .symbol-work/error.log

# Build a script for wrapping an SML/NJ heap image into an executable.
#
# The HEAP_IMAGE string will be replaced with the path to the heap image when
# installing the script (because prefix might change from one install to the
# next).
.symbol-work/smlnj/$(target)-wrapper.sh:
	mkdir -p "$(@D)"
	echo '#!/usr/bin/env bash' > "$@"
	echo '' >> "$@"
	echo 'exec $(SML) @SMLcmdname="$$0" @SMLload="HEAP_IMAGE" "$$@"' >> "$@"

# ----- mlton -----

ifeq ($(with),mlton)
# Given an MLBasis file, builds a makefile that records which sources files
# could cause the MLton executable to become out of date.
#
# Effectively simulates ml-makedepend, but for MLton's MLBasis files.
#
# The resulting makefile is conditionally included below, so it will take
# effect after the first build.
#
# We remove the file if the build step failed, so that Make doesn't think
# we succeeded and never re-run us.
.symbol-work/mlton/$(target).mlb.mk: $(target).mlb
	./symbol log info "Analyzing MLB dependencies..." >&3
	mkdir -p "$(@D)"
	echo '# DO NOT EDIT autogenerated mlton dependencies' > "$@"
	echo '.symbol-work/mlton/$(target): \\' >> "$@"
	$(MLTON) -stop f "$<" | sed -e 's/$$/ \\/' >> "$@" || rm -f "$@"

# Only include the makefile once it's been built
-include .symbol-work/mlton/$(target).mlb.mk
endif

# Build a MLton executable
.symbol-work/mlton/$(target): .symbol-work/mlton/$(target).mlb.mk
	./symbol log info "Building binary with MLton..." >&3
	mkdir -p "$(@D)"
	$(MLTON) \
		 $(MLTONFLAGS) \
		 -prefer-abs-paths true \
		 -show-def-use $(target).du \
		 -output "$(@)" \
		 $(target).mlb 2>&1 | tee .symbol-work/error.log
