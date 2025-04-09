# add license header to every source file
add-license:
	@awk -i inplace 'FNR==1 && !/SPDX-License-Identifier/ {print "// SPDX-License-Identifier: MPL-2.0\n"}1' */sources/*.move */tests/*.move
# with reuse tool:
# docker run --rm --volume $(pwd):/data fsfe/reuse annotate --license MPL-2.0  */tests/*.move */sources/*.move  -s cpp
