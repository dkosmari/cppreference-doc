#   Copyright (C) 2011-2014  Povilas Kanapickas <povilas@radix.lt>
#
#   This file is part of cppreference-doc
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see http://www.gnu.org/licenses/.

PREFIX ?= /usr
datarootdir = $(PREFIX)/share
docdir = $(datarootdir)/cppreference/doc
bookdir = $(datarootdir)/devhelp/books

qhelpgenerator ?= qhelpgenerator

VERSION := $(shell date +%Y%m%d)

DOWNLOAD_DIR := download

DISTFILES := \
	build_link_map.py		\
	commands/			\
	ddg_parse_html.py		\
	devhelp2qch.py			\
	export.py			\
	fix_devhelp-links.py		\
	gadgets/			\
	headers/			\
	images/				\
	index-chapters-c.xml		\
	index-chapters-cpp.xml		\
	index-cpp-search-app.txt	\
	index-functions-c.xml		\
	index-functions-cpp.xml		\
	index-functions.README		\
	index2autolinker.py		\
	index2browser.py		\
	index2ddg.py			\
	index2devhelp.py		\
	index2doxygen-tag.py		\
	index2highlight.py		\
	index2search.py			\
	index_transform/		\
	link_map.py			\
	Makefile			\
	preprocess-css.css		\
	preprocess.py			\
	preprocess_qch.py		\
	README.md			\
	reference/			\
	skins/				\
	test.sh				\
	tests/				\
	xml_utils.py

CLEANFILES := output

TAR_FORMAT := gz
TAR_OPTION := z
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	TAR_FORMAT := xz
	TAR_OPTION := J
endif
TARBALL := cppreference-doc-$(VERSION).tar.$(TAR_FORMAT)


.PHONY: 			\
	all 			\
	clean 			\
	devhelp 		\
	dist 			\
	download 		\
	doxygen 		\
	html 			\
	html-cssless 		\
	indexes 		\
	install 		\
	install-devhelp 	\
	install-html 		\
	install-qch 		\
	link-map 		\
	qch 			\
	uninstall 		\
	uninstall-devhelp 	\
	uninstall-html 		\
	uninstall-qch


all: html devhelp qch doxygen


clean:
	$(RM) -r $(CLEANFILES)


dist:
	mkdir -p cppreference-doc-$(VERSION)
	cp -r $(DISTFILES) cppreference-doc-$(VERSION)
	tar c$(TAR_OPTION)f $(TARBALL) cppreference-doc-$(VERSION)
	$(RM) -r cppreference-doc-$(VERSION)


install: install-html install-devhelp install-qch


uninstall: uninstall-html uninstall-devhelp uninstall-qch


release: all
	$(RM) -r release
	mkdir -p release

	mkdir -p cppreference-doc-$(VERSION)
	cp -r $(DISTFILES) cppreference-doc-$(VERSION)
	tar c$(TAR_OPTION)f release/$(TARBALL) cppreference-doc-$(VERSION)
	zip -qr release/cppreference-doc-$(VERSION).zip cppreference-doc-$(VERSION)
	$(RM) -r cppreference-doc-$(VERSION)
	cd output && \
		tar c$(TAR_OPTION)f ../release/html-book-$(VERSION).tar.$(TAR_FORMAT) \
			reference \
			cppreference-doxygen-local.tag.xml \
			cppreference-doxygen-web.tag.xml
	cd output && \
		zip -qr ../release/html-book-$(VERSION).zip \
			reference \
			cppreference-doxygen-local.tag.xml \
			cppreference-doxygen-web.tag.xml
	cd output && \
		tar c$(TAR_OPTION)f ../release/qch-book-$(VERSION).tar.$(TAR_FORMAT) \
			cppreference-doc-en-cpp.qch
	cd output && \
		zip -qr ../release/qch-book-$(VERSION).zip \
			cppreference-doc-en-cpp.qch

output:
	mkdir -p $@


output/indexes:
	mkdir -p $@


indexes: 				\
		index-functions-c.xml 	\
		index-functions-cpp.xml \
		index2autolinker.py 	\
		index2highlight.py 	\
		index2search.py 	\
		| output/indexes
	./index2autolinker.py index-functions-c.xml output/indexes/autolink-c
	./index2autolinker.py index-functions-cpp.xml output/indexes/autolink-cpp
	./index2highlight.py index-functions-c.xml   output/indexes/highlight-c
	./index2highlight.py index-functions-cpp.xml output/indexes/highlight-cpp
	./index2search.py index-functions-c.xml   output/indexes/search-c
	./index2search.py index-functions-cpp.xml output/indexes/search-cpp


# redownload the source documentation directly from en.cppreference.com
download: export.py | wiki
	$(RM) -r $(DOWNLOAD_DIR)
	mkdir -p $(DOWNLOAD_DIR)
	REGEX='index\.php' \
	REGEX+='|/(Special|Talk|Help|File|Cppreference):' \
	REGEX+='|/(WhatLinksHere|Template|Category):' \
	REGEX+='|(action|printable)=' \
	REGEX+='|en\.cppreference\.com/book' \
	REGEX+='|robots\.txt' ; \
	wget \
		--adjust-extension \
		--convert-links \
		--directory-prefix=$(DOWNLOAD_DIR) \
		--execute robots=off \
		--domains=en.cppreference.com,upload.cppreference.com \
		--force-directories \
		--level=inf \
		--no-verbose \
		--page-requisites \
		--read-timeout=20 \
		--recursive \
		--reject-regex="$$REGEX" \
		--retry-connrefused \
		--span-hosts \
		--timeout=10 \
		--waitretry=10 \
		https://en.cppreference.com/w/ || true
	./export.py --url=https://en.cppreference.com/mwiki \
		$(DOWNLOAD_DIR)/cppreference-export-ns0,4,8,10.xml \
		0 4 8 10


link-map: html
	./build_link_map.py


html: | output
	./preprocess.py --src $(DOWNLOAD_DIR) --dst output/reference


html-cssless: html preprocess_qch.py
	./preprocess_qch.py --src output/reference --dst output/reference_cssless


install-html: html
	cd output/reference && \
		find . -type f \
			-exec install -DT -m 644 '{}' '$(DESTDIR)$(docdir)/html/{}' ';'


uninstall-html:
	$(RM) -r $(DESTDIR)$(docdir)/html


devhelp: link-map | indexes
	./index2highlight.py index-functions-c.xml output/indexes/highlight-c
	./index2devhelp.py 				\
		--base $(docdir)/html 			\
		--chapters index-chapters-c.xml  	\
		--title "C Standard Library reference" 	\
		--name cppreference-doc-en-c 		\
		--rel c 				\
		--src index-functions-c.xml 		\
		--dst output/devhelp-index-c.xml 	\
		--lang c
	./index2devhelp.py 					\
		--base $(docdir)/html 				\
		--chapters index-chapters-cpp.xml 		\
		--title "C++ Standard Library reference" 	\
		--name cppreference-doc-en-cpp 			\
		--rel cpp 					\
		--src index-functions-cpp.xml 			\
		--dst output/devhelp-index-cpp.xml 		\
		--lang c++
	./fix_devhelp-links.py output/devhelp-index-c.xml output/cppreference-doc-en-c.devhelp2
	./fix_devhelp-links.py output/devhelp-index-cpp.xml output/cppreference-doc-en-cpp.devhelp2


install-devhelp: devhelp doxygen install-html
	install -DT -m 644 output/cppreference-doc-en-c.devhelp2 \
		$(DESTDIR)$(bookdir)/cppreference-doc-en-c/cppreference-doc-en-c.devhelp2
	install -DT -m 644 output/cppreference-doc-en-cpp.devhelp2 \
		$(DESTDIR)$(bookdir)/cppreference-doc-en-cpp/cppreference-doc-en-cpp.devhelp2
	install -DT -m 644 output/cppreference-doxygen-local.tag.xml \
		$(DESTDIR)$(bookdir)/cppreference-doxygen-local.tag.xml
	install -DT -m 644 output/cppreference-doxygen-web.tag.xml \
		$(DESTDIR)$(bookdir)/cppreference-doxygen-web.tag.xml


uninstall-devhelp:
	$(RM) -r $(DESTDIR)$(bookdir)/cppreference-doc-en-c
	$(RM) -r $(DESTDIR)$(bookdir)/cppreference-doc-en-cpp
	$(RM) $(DESTDIR)$(bookdir)/cppreference-doxygen-local.tag.xml
	$(RM) $(DESTDIR)$(bookdir)/cppreference-doxygen-web.tag.xml


qch: devhelp
	./preprocess_qch.py --src output/reference --dst output/reference_cssless --verbose
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<files>\n' > output/qch-files.xml
	(cd output/reference_cssless; find . -type f -not -iname '*.ttf' -printf '  <file>%p</file>\n' | LC_ALL=C sort) >> output/qch-files.xml
	printf '</files>\n' >> output/qch-files.xml
	./devhelp2qch.py 					\
		--src=output/cppreference-doc-en-cpp.devhelp2 	\
		--file_list=output/qch-files.xml 		\
		--virtual_folder=cpp 				\
		--dst=output/qch-help-project-cpp.xml
	ln -s output/qch-help-project-cpp.xml output/reference_cssless/qch.qhp
	cd output/reference_cssless ; \
		$(qhelpgenerator) \
			qch.qhp \
			-o ../cppreference-doc-en-cpp.qch
	$(RM) output/reference_cssless/qch.qhp


install-qch: qch
	install -DT -m 644 output/cppreference-doc-en-cpp.qch \
		$(DESTDIR)$(docdir)/qch/cppreference-doc-en-cpp.qch


uninstall-qch:
	$(RM) $(DESTDIR)$(docdir)/qch/cppreference-doc-en-cpp.qch


doxygen: 				\
		link-map 		\
		index-functions-cpp.xml \
		index-chapters-cpp.xml 	\
		| output
	./index2doxygen-tag.py 					\
		output/link-map.xml 				\
		index-functions-cpp.xml 			\
		index-chapters-cpp.xml 				\
		output/cppreference-doxygen-local.tag.xml
	./index2doxygen-tag.py web 			\
		index-functions-cpp.xml 		\
		index-chapters-cpp.xml 			\
		output/cppreference-doxygen-web.tag.xml
