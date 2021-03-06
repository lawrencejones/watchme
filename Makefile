COFFEE := ./node_modules/coffee-script/bin/coffee
COFFEE_FLAGS := --compile --bare
PEG := ./node_modules/pegjs/bin/pegjs

# Setup file locations
SRC_DIR  := src
LIB_DIR  := lib
TEST_DIR := test

# Glob all the coffee source
ALL := $(wildcard $(SRC_DIR)/*.coffee | sort)
SRC := $(filter-out lib/cmd_parser.js,$(ALL))
LIB := $(SRC:$(SRC_DIR)/%.coffee=$(LIB_DIR)/%.js) lib/cmd_parser.js

.PHONY: all clean rebuild test watch

# Phony all target
all: $(LIB_DIR) $(LIB)
	@-echo "Finished building watchme."
 
# Produces folder for js
$(LIB_DIR):
	@mkdir $@

# Phony clean target
clean:
	@-echo "Cleaning *.js files"
	@-rm -f $(LIB)

# Phony rebuild target
rebuild: clean all

# Runs mocha tests
PATTERN ?= ''
test:
	./node_modules/mocha/bin/mocha\
		--recursive --compilers coffee:coffee-script/register\
		--reporter spec\
		--colors\
		--growl\
		--grep ${PATTERN}

# Watch for changes and rerun tests
watch:
	watchme -c ./src ./test -e "make test"

# Build the pegjs parser
lib/cmd_parser.js: src/grammar.pegjs
	@-echo "  Compiling $@"
	@$(PEG) $< $@

# Rule for all other coffee files
lib/%.js: src/%.coffee
	@-echo "  Compiling $@"
	@$(COFFEE) $(COFFEE_FLAGS) -o $(LIB_DIR) $^

