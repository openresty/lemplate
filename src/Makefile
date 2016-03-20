.PHONY: fetch runtime

.DELETE_ON_ERROR: $(RUNTIME_MODULE) $(RUNTIME_COMPACT_MODULE)

JEMPLATE_SCRIPT=../bin/lemplate
JEMPLATE_STANDALONE_SCRIPT=../lemplate
GRAMMAR_MODULE=../lib/Lemplate/Grammar.pm
JEMPLATE_MODULES=$(GRAMMAR_MODULE) $(RUNTIME_MODULE) $(RUNTIME_COMPACT_MODULE)

all: $(JEMPLATE_STANDALONE_SCRIPT)

$(JEMPLATE_STANDALONE_SCRIPT): $(JEMPLATE_MODULES) _force
	./bin/make-standalone-script $(JEMPLATE_SCRIPT) > $@
	chmod +x $@

$(GRAMMAR_MODULE): parser _force
	(cd parser; ./yc)
	mv parser/Grammar.pm $@
	rm parser/Parser.output

_force:
