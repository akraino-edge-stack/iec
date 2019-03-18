##############################################################################
# Copyright (c) 2019 Akraino IEC
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# Components pinning / remote tracking
##############################################################################

# git submodule & patch locations for IEC components
GIT_ROOT   := $(shell git rev-parse --show-toplevel)
GIT_DIR    := $(shell git rev-parse --git-dir)
PATCH_DIR  := $(shell pwd)/seba_on_arm/patches
IEC_TAG    := master-iec

# Akraino IEC relies on upstream git repos (one per component) in 1 of 2 ways:
# - pinned down to tag objects (e.g. "9.0.1")
# - tracking upstream remote HEAD on a stable or master branch

# To enable remote tracking, set the following var to any non-empty string.
# Leaving this var empty will bind each git submodule to its saved commit,
# avoiding risk of patch no longer applying after upstream changes.
IEC_TRACK_REMOTES ?=

export GIT_COMMITTER_NAME?=Akraino IEC
export GIT_COMMITTER_EMAIL?=blueprints@lists.akraino.org
