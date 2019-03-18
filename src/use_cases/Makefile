##############################################################################
# Copyright (c) 2019 Akraino IEC
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

include config.mk

SHELL = /bin/sh
FPATCHES = $(shell find ${PATCH_DIR} -name '*.patch')

# NOTE: Mechanism overview is presented in ./README.rst.

# Submodule consistent states:
#   - NOT initialized (submodule trees are not populated at all);
#   - initialized, bound to saved commits;
#   - initialized, tracking remote origin (only for IEC_TRACK_REMOTES);
#   - patched (local patches are applied);

.PHONY: all
all: sub

##############################################################################
# git submodule operations - to be used stand-alone or from parent Makefile
##############################################################################

# Fetch & update git submodules, checkout remote HEAD or saved commit
.PHONY: sub
sub: .cacheiecinfo

.cacheiecinfo:
	@if [ -n "${IEC_TRACK_REMOTES}" ]; then \
		cd ${GIT_ROOT} && git submodule update --init --remote 2>/dev/null; \
	else \
		cd ${GIT_ROOT} && git submodule update --init 2>/dev/null; \
	fi
	@touch $@

# Generate patches from submodules
.PHONY: patches-export
patches-export: sub
	@git submodule -q foreach ' \
		SUB_DIR=${PATCH_DIR}/$$name; \
		rm -rf $$SUB_DIR/*; \
		git tag | awk "!/root/ && /${IEC_TAG}-iec/" | while read TAG; do \
			SUB_FEATURE=`dirname $${TAG#${IEC_TAG}-iec/}`; \
			echo "`tput setaf 2`-- exporting $$name ($$TAG)`tput sgr0`"; \
			mkdir -p $$SUB_DIR/$${SUB_FEATURE} && \
			git format-patch --no-signature --ignore-space-at-eol \
				-o $$SUB_DIR/$$SUB_FEATURE -N $$TAG-root..$$TAG; \
			sed -i -e "1{/From: /!d}" -e "s/[[:space:]]*$$//" \
				$$SUB_DIR/$$SUB_FEATURE/*.patch; \
		done'

# Apply patches from patch/* to respective submodules
# We rely on `make sub` and/or `make clean` to checkout correct base
.PHONY: patches-import
patches-import: sub .cachepatched

.cachepatched: ${FPATCHES}
	@$(MAKE) clean
	@cd ${GIT_ROOT} && git submodule -q foreach ' \
		SUB_DIR=${PATCH_DIR}/$$name; mkdir -p $$SUB_DIR && \
		git tag ${IEC_TAG}-root && \
		git checkout -q -b akraino-iec && \
		find $$SUB_DIR -type d | sort | while read p_dir; do \
			SUB_PATCHES=$$(ls $$p_dir/*.patch 2>/dev/null); \
			if [ -n "$$SUB_PATCHES" ]; then \
				SUB_FEATURE=$${p_dir#$$SUB_DIR}; \
				SUB_TAG=${IEC_TAG}-iec$$SUB_FEATURE/patch; \
				echo "`tput setaf 2`-- patching $$name ($$SUB_TAG)`tput sgr0`";\
				git tag $$SUB_TAG-root && \
				git am -3 --ignore-whitespace --patch-format=mbox \
					--committer-date-is-author-date $$SUB_PATCHES && \
				git tag $$SUB_TAG || exit 1; \
			fi \
		done && \
		git tag ${IEC_TAG}'
	@touch $@

# Add copyright header to patch files if not already present
.PHONY: patches-copyright
patches-copyright:
	@grep -e "Copyright (c)" -L ${FPATCHES} | while read p_file; do \
		ptmp=`mktemp` && \
		cat iec-patch-copyright.template $$p_file > $$ptmp && \
		mv $$ptmp $$p_file; \
	done

# Clean any changes made to submodules, checkout upstream IEC root commit
.PHONY: clean
clean:
	@cd ${GIT_ROOT} && git submodule -q foreach ' \
		git am -q --abort > /dev/null 2>&1; \
		git checkout -q -f ${IEC_TAG}-root > /dev/null 2>&1; \
		git branch -q -D akraino-iec > /dev/null 2>&1; \
		git tag | grep ${IEC_TAG} | xargs git tag -d > /dev/null 2>&1; \
		git reset -q --hard HEAD; \
		git clean -xdff'
	@rm -f .cachepatched

.PHONY: deepclean
deepclean: clean
	@cd ${GIT_ROOT} && git submodule deinit -f ${GIT_ROOT}
	@rm -f .cache*
