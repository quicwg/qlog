LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
	git reset --hard 0c86ef463bd8e3516588c99446938ac665875e5b
endif

# run cddl_validate.sh for all drafts_source files 
cddl:
	@for f in $(drafts_source); do \
	    echo "Validating $$f"; \
	    ./cddl_validate.sh $$f > /tmp/foo-$$f 2>&1 ; \
	    if [ $$? -eq 0 ]; then \
	        echo "  OK"; \
	    else \
	        echo "  ERROR"; \
					echo "  debug with: ./cddl_validate.sh $$f"; \
	    fi; \
	done

# override lib/main.mk clean target, to cleanup json and cddl files
.PHONY: clean
clean::
		$(MAKE) -f $(LIBDIR)/main.mk $@
		-rm -f \
	    $(addsuffix -[0-9][0-9].{json$(COMMA)cddl},$(drafts)) \
	    $(addsuffix .{json$(COMMA)cddl},$(drafts)) \
			Gemfile.lock

# override lib/main.mk all target, to also install deps from Gemfile
.PHONY: all
all:: cddl
		$(MAKE) -f $(LIBDIR)/main.mk $@
