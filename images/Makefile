.PHONY: all
all: squid

.PHONY: squid
squid:
	docker build squid -t yokaze/squid-builder:dev --target builder
	docker build squid -t yokaze/squid:dev
