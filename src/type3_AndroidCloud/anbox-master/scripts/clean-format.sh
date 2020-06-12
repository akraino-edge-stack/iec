#!/bin/sh
# shellcheck source=/dev/null

find src -name "*.h" | xargs clang-format -style=file -i
find src -name "*.cpp" | xargs clang-format -style=file -i
