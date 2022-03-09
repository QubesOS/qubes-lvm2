DIST ?= fc32
VERSION := $(shell cat version)
REL := $(shell cat rel)

FEDORA_SOURCES := https://src.fedoraproject.org/rpms/lvm2/raw/f$(subst fc,,$(DIST))/f/sources
SRC_FILE := LVM2.$(VERSION).tgz

BUILDER_DIR ?= ../..
SRC_DIR ?= qubes-src

DISTFILES_MIRROR ?= https://sourceware.org/pub/lvm2/LVM2.$(VERSION).tgz
UNTRUSTED_SUFF := .UNTRUSTED

ifeq ($(FETCH_CMD),)
$(error "You can not run this Makefile without having FETCH_CMD defined")
endif

SHELL := /bin/bash

keyring := lvm2-trustedkeys.gpg
keyring-file := $(if $(GNUPGHOME), $(GNUPGHOME)/, $(HOME)/.gnupg/)$(keyring)
keyring-import := gpg -q --no-auto-check-trustdb --no-default-keyring --import

$(keyring-file): $(wildcard *-key.asc)
	@rm -f $(keyring-file) && $(keyring-import) --keyring $(keyring) $^

$(SRC_FILE).asc:
	$(FETCH_CMD) $@ $(DISTFILES_MIRROR).asc

%: %.asc $(keyring-file)
	@$(FETCH_CMD) $@$(UNTRUSTED_SUFF) $(DISTFILES_MIRROR)
	@gpgv --keyring $(keyring) $< $@$(UNTRUSTED_SUFF) 2>/dev/null || \
		{ echo "Wrong signature on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

%: %.sha512
	@$(FETCH_CMD) $@$(UNTRUSTED_SUFF) $(DISTFILES_MIRROR)$@
	@sha512sum --status -c <(printf "$$(cat $<)  -\n") <$@$(UNTRUSTED_SUFF) || \
		{ echo "Wrong SHA512 checksum on $@$(UNTRUSTED_SUFF)!"; exit 1; }
	@mv $@$(UNTRUSTED_SUFF) $@

.PHONY: get-sources
get-sources: $(SRC_FILE)

.PHONY: verify-sources
verify-sources:
	@true

.PHONY: clean
clean:
	rm -rf debian/changelog.*
	rm -rf pkgs

# This target is generating content locally from upstream project
# 'sources' file. Sanitization is done but it is encouraged to perform
# update of component in non-sensitive environnements to prevent
# any possible local destructions due to shell rendering
.PHONY: update-sources
update-sources:
	@$(BUILDER_DIR)/$(SRC_DIR)/builder-rpm/scripts/generate-hashes-from-sources $(FEDORA_SOURCES)
