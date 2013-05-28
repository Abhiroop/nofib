#################################################################################
#
#			    nofib/mk/boilerplate.mk
#
#		Boilerplate Makefile for an fptools project
#
#################################################################################

# Begin by slurping in the boilerplate from one level up, 
# with standard TOP-mangling
# Remember, TOP is the top level of the innermost level

default : all

show:
	@echo '$(VALUE)="$($(VALUE))"'

NOFIB_TOP := $(TOP)
include $(NOFIB_TOP)/../mk/tree.mk
include $(NOFIB_TOP)/../mk/config.mk
include $(NOFIB_TOP)/../mk/custom-settings.mk
TOP := $(NOFIB_TOP)

RM = rm -f
SIZE = size
STRIP = strip

# Turn off -Werror for nofib. This allows you to use nofib in a tree
# built with validate.
WERROR=

# Benchmarks controls which set of tests should be run
# You can run one or more of
#	imaginary 
#	spectral
#	real
#	parallel
#	gc
#	smp
#	fibon
NoFibSubDirs = imaginary spectral real shootout

# Haskell compiler options for nofib
NoFibHcOpts = -O2

# Number of times to run each program
NoFibRuns = 5

# -----------------------------------------------------------------
# Everything after this point
# augments or overrides previously set variables.
# (these files are optional, so `make' won't fret if it
#  cannot get to them).
# -----------------------------------------------------------------

SRC_HC_OPTS += $(NoFibHcOpts) -Rghc-timing

# -package array is needed for GHC 7.0.1 and later, as the haskell98 package
# is no longer linked by default.  We would like to use
#    -hide-all-packages -package haskell2010
# instead, but there is at least one program that uses a non-haskell2010
# library module (fibheaps uses Control.Monad.ST)
SRC_HC_OPTS += -package array

ifeq "$(WithNofibHc)" ""

STAGE1_GHC := $(abspath $(TOP)/../inplace/bin/ghc-stage1)
STAGE2_GHC := $(abspath $(TOP)/../inplace/bin/ghc-stage2)
STAGE3_GHC := $(abspath $(TOP)/../inplace/bin/ghc-stage3)

ifneq "$(wildcard $(STAGE1_GHC) $(STAGE1_GHC).exe)" ""

ifeq "$(BINDIST)" "YES"
HC := $(abspath $(TOP)/../)/bindisttest/install   dir/bin/ghc
else ifeq "$(stage)" "1"
HC := $(STAGE1_GHC)
else ifeq "$(stage)" "3"
HC := $(STAGE3_GHC)
else
# use stage2 by default
HC := $(STAGE2_GHC)
endif

else
HC := $(shell which ghc)
endif

else

# We want to support both "ghc" and "/usr/bin/ghc" as values of WithNofibHc
# passed in by the user, but
#     which ghc          == /usr/bin/ghc
#     which /usr/bin/ghc == /usr/bin/ghc
# so on unix-like platforms we can just always 'which' it.
# However, on cygwin, we can't just use which:
#     $ which c:/ghc/ghc-7.4.1/bin/ghc.exe
#     which: no ghc.exe in (./c:/ghc/ghc-7.4.1/bin)
# so we start off by using realpath, and if that succeeds then we use
# that value. Otherwise we fall back on 'which'.
HC_REALPATH := $(realpath $(WithNofibHc))
ifeq "$(HC_REALPATH)" ""
HC := $(shell which '$(WithNofibHc)')
else
HC := $(HC_REALPATH)
endif

endif

MKDEPENDHS := $(HC) # ToDo: wrong, if $(HC) isn't GHC.

define get-ghc-rts-field # $1 = result variable, $2 = field name
$1 := $$(shell '$$(HC)' +RTS --info | grep '^ .("$2",' | tr -d '\r' | sed -e 's/.*", *"//' -e 's/")$$$$//')
endef

$(eval $(call get-ghc-rts-field,HC_VERSION,GHC version))

define ghc-ge # $1 = major version, $2 = minor version
HC_VERSION_GE_$1_$2 := $$(shell if [ `echo $$(HC_VERSION) | sed 's/\..*//'` -gt $1 ]; then echo YES; else if [ `echo $$(HC_VERSION) | sed 's/\..*//'` -ge $1 ] && [ `echo $$(HC_VERSION) | sed -e 's/[^.]*\.//' -e 's/\..*//'` -ge $2 ]; then echo YES; else echo NO; fi; fi)
endef

$(eval $(call ghc-ge,6,13))

RUNTEST   = $(NOFIB_TOP)/runstdtest/runstdtest

include $(NOFIB_TOP)/mk/ghc-paths.mk
include $(NOFIB_TOP)/mk/ghc-opts.mk
include $(NOFIB_TOP)/mk/paths.mk
include $(NOFIB_TOP)/mk/opts.mk

-include .depend
