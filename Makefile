#
# Build instructions
#

# Make sure that any failure in a pipe fails the build
SHELL = /bin/bash -o pipefail

# Compile and test
.PHONY: all
all:
	nim c -r binaryheap.nim

# Watches for changes and reruns
.PHONY: watch
watch:
	$(eval MAKEFLAGS += " -s ")
	@while true; do \
		make; \
		echo "Done. Watching for changes"; \
		inotifywait -qre close_write `find . -name "*.nim"` > /dev/null; \
		echo "Change detected, re-running..."; \
	done

# Remove all build artifacts
.PHONY: clean
clean:
	rm -f binaryheap
	rm -rf nimcache

