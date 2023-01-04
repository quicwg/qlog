LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

# run cddl_validate.sh for all drafts_source files 
cddl: $(drafts_source)
	@for f in $^; do \
	    echo "Validating $$f"; \
	    ./cddl_validate.sh $$f > /tmp/foo 2>&1 ; \
	    if [ $$? -eq 0 ]; then \
	        echo "  OK"; \
	    else \
	        echo "  ERROR"; \
					echo "  debug with: ./cddl_validate.sh $$f"; \
	    fi; \
	done

# override lib/main.mk deps target, to also install deps from Gemfile
.PHONY: deps
deps::
		$(MAKE) -f $(LIBDIR)/main.mk $@
		bundle install --gemfile=$(realpath $<)

# override lib/main.mk clean target, to cleanup json and cddl files
.PHONY: clean
clean::
		$(MAKE) -f $(LIBDIR)/main.mk $@
		-rm -f \
	    $(addsuffix -[0-9][0-9].{json$(COMMA)cddl},$(drafts))
