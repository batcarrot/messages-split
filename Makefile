.PHONY: generate open test-python test-swift

generate:
	xcodegen generate

open: generate
	open SplitMessages.xcodeproj

test-python:
	python3 scripts/validate_split_logic.py -v

test-swift:
	cd Packages/SplitCore && swift test
