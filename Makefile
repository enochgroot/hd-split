.PHONY: all build clean test
build    :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=200 dapp --use solc:0.8.0 build
clean    :; dapp clean
test     :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=200 dapp --use solc:0.8.0 test -v ${TEST_FLAGS}
