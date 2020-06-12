#!/bin/sh
# shellcheck source=/dev/null
PACKAGE=com.android.settings

exec $SNAP/bin/anbox-wrapper.sh launch \
	--package="$PACKAGE"
