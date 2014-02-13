
include Makefile.config

all:
	ocp-build

install:
	sudo cp $(OBUILD)/ocp-manager/ocp-manager.asm $(BINDIR)/ocp-manager
	ocp-manager -list
	@echo 
	@echo "Don't forget to update your configuration files with"
	@echo 
	@echo '    eval `ocp-manager -config`'
	@echo

install.user:
	$(OBUILD)/ocp-manager/ocp-manager.asm

