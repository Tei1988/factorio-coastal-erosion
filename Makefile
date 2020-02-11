ZIP=zip
RM=rm
FACTORIO_MOD_VERSION=0.0.6
FACTORIO_MOD_NAME=coastal-erosion
MOD_VERSIONED_NAME=${FACTORIO_MOD_NAME}_${FACTORIO_MOD_VERSION}
OUTPUT=${MOD_VERSIONED_NAME}.zip

NPM=docker run -u $(id -u):$(id -g) --entrypoint npm -w /src -v ${PWD}:/src -it --rm circleci/node:12-buster

.PHONY: all
all: setup

.PHONY: setup
setup: ${OUTPUT}

${OUTPUT}: ${MOD_VERSIONED_NAME}
	${NPM} run-script build
	sed -i "s/^function __TS__/local function __TS__/g" $</*.lua
	sed -i "s/to_be_replaced/${FACTORIO_MOD_VERSION}/g" $</info.json
	zip -r $@ $<
	rm -r $<

${MOD_VERSIONED_NAME}:
	cp -r ${FACTORIO_MOD_NAME} $@

.PHONY: clean
clean:
	${RM} -f ${OUTPUT}
	${RM} -rf ${MOD_VERSIONED_NAME}

.PHONY: install
install:
	cp -f ${OUTPUT} ~/Library/Application\ Support/factorio/mods/
