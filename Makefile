SHELL=/usr/bin/env sh

all: build spec docs/

shards.yml:
lib/: shards.yml dependencies

.shards/: lib/

src/: build spec

docs/: lib/ src/
	crystal docs

dependencies: shard.yml
	shards update

build: .shards/ lib/
	crystal build src/owocr.cr

spec: build
	crystal spec

clean:
	rm owocr
	rm -rf .shards/ lib/ docs/

_PHONY: build spec clean dependencies