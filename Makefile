LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update --init
else
ifneq (,$(wildcard $(ID_TEMPLATE_HOME)))
	ln -s "$(ID_TEMPLATE_HOME)" $(LIBDIR)
else
	git clone -q --depth 10 -b main \
	    https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
endif

cddl:: $(addsuffix .cddl,$(drafts))

# run cddl_validate.sh for all changed files
%.cddl: %.md
	@for f in $@; do \
	    echo "Validating $$f"; \
		./cddl_validate.sh $$f > /tmp/foo-$$f 2>&1 ; \
	    if [ $$? -eq 0 ]; then \
	        echo "  OK"; \
	    else \
	        echo "  ERROR $$? : "; \
					echo "  debug with: ./cddl_validate.sh $$f"; \
	    fi; \
	done

# override lib/main.mk clean target, to cleanup json and cddl files
.PHONY: clean
clean::
		$(MAKE) -f $(LIBDIR)/main.mk $@
		-rm -f \
	    $(addsuffix -[0-9][0-9].{json$(COMMA)cddl},$(drafts)) \
	    $(addsuffix .{json$(COMMA)cddl},$(drafts))

# override lib/main.mk all target, to also install deps from Gemfile
.PHONY: all
all:: cddl
		$(MAKE) -f $(LIBDIR)/main.mk $@
