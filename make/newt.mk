###########################################################
#
# newt
#
###########################################################

#
# NEWT_REPOSITORY defines the upstream location of the source code
# for the package.  NEWT_DIR is the directory which is created when
# this cvs module is checked out.
#

NEWT_REPOSITORY=:pserver:anonymous@elvis.redhat.com:/usr/local/CVS
NEWT_SITE=$(SOURCES_NLO_SITE)
NEWT_VERSION=0.52.7
NEWT_DIR=newt-$(NEWT_VERSION)
NEWT_SOURCE=newt-$(NEWT_VERSION).tar.gz
NEWT_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
NEWT_DESCRIPTION=Not Erik''s Windowing Toolkit - text mode windowing with slang.
NEWT_SECTION=lib
NEWT_PRIORITY=optional
NEWT_DEPENDS=popt, slang
ifeq ($(GETTEXT_NLS), enable)
NEWT_DEPENDS+=, gettext
endif
NEWT_SUGGESTS=
NEWT_CONFLICTS=

#
# Software downloaded from CVS repositories must either use a tag or a
# date to ensure that the same sources can be downloaded later.
#

#
# If you want to use a date, uncomment the variables below and modify
# NEWT_CVS_DATE
#

#NEWT_CVS_DATE=20050201
#NEWT_VERSION=cvs$(NEWT_CVS_DATE)
#NEWT_CVS_OPTS=-D $(NEWT_CVS_DATE)

#
# If you want to use a tag, uncomment the variables below and modify
# NEWT_CVS_TAG and NEWT_CVS_VERSION
#

#NEWT_CVS_TAG=r0-52-7
#NEWT_VERSION=0.52.7
#NEWT_CVS_OPTS=-r $(NEWT_CVS_TAG)

#
# NEWT_IPK_VERSION should be incremented when the ipk changes.
#
NEWT_IPK_VERSION=1

#
# NEWT_CONFFILES should be a list of user-editable files
NEWT_CONFFILES=

#
# NEWT_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
NEWT_PATCHES=$(NEWT_SOURCE_DIR)/Makefile.in.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
NEWT_CPPFLAGS=
NEWT_LDFLAGS=
ifeq ($(LIBC_STYLE), uclibc)
NEWT_LDFLAGS+=-lintl
endif

#
# NEWT_BUILD_DIR is the directory in which the build is done.
# NEWT_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# NEWT_IPK_DIR is the directory in which the ipk is built.
# NEWT_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
NEWT_BUILD_DIR=$(BUILD_DIR)/newt
NEWT_SOURCE_DIR=$(SOURCE_DIR)/newt
NEWT_IPK_DIR=$(BUILD_DIR)/newt-$(NEWT_VERSION)-ipk
NEWT_IPK=$(BUILD_DIR)/newt_$(NEWT_VERSION)-$(NEWT_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: newt-source newt-unpack newt newt-stage newt-ipk newt-clean newt-dirclean newt-check

#
# In this case there is no tarball, instead we fetch the sources
# directly to the builddir with CVS
#
#$(DL_DIR)/$(NEWT_SOURCE):
#	( cd $(BUILD_DIR) ; \
#		rm -rf $(NEWT_DIR) && \
#		cvs -d $(NEWT_REPOSITORY) -z3 co $(NEWT_CVS_OPTS) -d $(NEWT_DIR) newt && \
#		tar -czf $@ $(NEWT_DIR) && \
#		rm -rf $(NEWT_DIR) \
#	)

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(NEWT_SOURCE):
	$(WGET) -P $(@D) $(NEWT_SITE)/$(@F)

newt-source: $(DL_DIR)/$(NEWT_SOURCE)

#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <foo>-stage <baz>-stage").
#
$(NEWT_BUILD_DIR)/.configured: $(DL_DIR)/$(NEWT_SOURCE) make/newt.mk
	$(MAKE) popt-stage python-stage slang-stage
ifeq ($(GETTEXT_NLS), enable)
	$(MAKE) gettext-stage
endif
	rm -rf $(BUILD_DIR)/$(NEWT_DIR) $(@D)
	tar -C $(BUILD_DIR) -xzf $(DL_DIR)/$(NEWT_SOURCE)
	if test -n "$(NEWT_PATCHES)" ; \
		then cat $(NEWT_PATCHES) | \
		$(PATCH) -bd $(BUILD_DIR)/$(NEWT_DIR) -p0 ; \
	fi
	if test "$(BUILD_DIR)/$(NEWT_DIR)" != "$(@D)" ; \
		then mv $(BUILD_DIR)/$(NEWT_DIR) $(@D) ; \
	fi
	sed -i -e 's/^AC_INIT(\(.*\))/AC_INIT([Newt], [$(NEWT_VERSION)])\nAC_CONFIG_SRCDIR(\1)\nAM_INIT_AUTOMAKE/' $(@D)/configure.ac
	-$(AUTORECONF1.10) -vif $(@D)
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(NEWT_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(NEWT_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=$(TARGET_PREFIX) \
		--disable-nls \
		--without-tcl \
	)
	touch $@

newt-unpack: $(NEWT_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(NEWT_BUILD_DIR)/.built: $(NEWT_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D) \
		STAGING_INCLUDE_DIR="$(STAGING_INCLUDE_DIR)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(NEWT_LDFLAGS)" \
		;
	touch $@

#
# This is the build convenience target.
#
newt: $(NEWT_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
$(NEWT_BUILD_DIR)/.staged: $(NEWT_BUILD_DIR)/.built
	rm -f $@
	$(MAKE) -C $(NEWT_BUILD_DIR) DESTDIR=$(STAGING_DIR) install
	touch $@

newt-stage: $(NEWT_BUILD_DIR)/.staged

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/newt
#
$(NEWT_IPK_DIR)/CONTROL/control:
	@$(INSTALL) -d $(@D)
	@rm -f $@
	@echo "Package: newt" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(NEWT_PRIORITY)" >>$@
	@echo "Section: $(NEWT_SECTION)" >>$@
	@echo "Version: $(NEWT_VERSION)-$(NEWT_IPK_VERSION)" >>$@
	@echo "Maintainer: $(NEWT_MAINTAINER)" >>$@
	@echo "Source: $(SOURCES_NLO_SITE)/$(NEWT_SOURCE)" >>$@
	@echo "Description: $(NEWT_DESCRIPTION)" >>$@
	@echo "Depends: $(NEWT_DEPENDS)" >>$@
	@echo "Suggests: $(NEWT_SUGGESTS)" >>$@
	@echo "Conflicts: $(NEWT_CONFLICTS)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(NEWT_IPK_DIR)$(TARGET_PREFIX)/sbin or $(NEWT_IPK_DIR)$(TARGET_PREFIX)/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(NEWT_IPK_DIR)$(TARGET_PREFIX)/{lib,include}
# Configuration files should be installed in $(NEWT_IPK_DIR)$(TARGET_PREFIX)/etc/newt/...
# Documentation files should be installed in $(NEWT_IPK_DIR)$(TARGET_PREFIX)/doc/newt/...
# Daemon startup scripts should be installed in $(NEWT_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/S??newt
#
# You may need to patch your application to make it use these locations.
#
$(NEWT_IPK): $(NEWT_BUILD_DIR)/.built
	rm -rf $(NEWT_IPK_DIR) $(BUILD_DIR)/newt_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(NEWT_BUILD_DIR) instroot=$(NEWT_IPK_DIR) install
	rm -f $(NEWT_IPK_DIR)$(TARGET_PREFIX)/lib/libnewt.a
	$(STRIP_COMMAND) \
		$(NEWT_IPK_DIR)$(TARGET_PREFIX)/bin/whiptail \
		$(NEWT_IPK_DIR)$(TARGET_PREFIX)/lib/libnewt.so.[0-9]*.[0-9]*.[0-9]* \
		$(NEWT_IPK_DIR)$(TARGET_PREFIX)/lib/python*/site-packages/_snackmodule.so \
		;
#	$(INSTALL) -d $(NEWT_IPK_DIR)$(TARGET_PREFIX)/etc/
#	$(INSTALL) -m 644 $(NEWT_SOURCE_DIR)/newt.conf $(NEWT_IPK_DIR)$(TARGET_PREFIX)/etc/newt.conf
#	$(INSTALL) -d $(NEWT_IPK_DIR)$(TARGET_PREFIX)/etc/init.d
#	$(INSTALL) -m 755 $(NEWT_SOURCE_DIR)/rc.newt $(NEWT_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/SXXnewt
	$(MAKE) $(NEWT_IPK_DIR)/CONTROL/control
#	$(INSTALL) -m 755 $(NEWT_SOURCE_DIR)/postinst $(NEWT_IPK_DIR)/CONTROL/postinst
#	$(INSTALL) -m 755 $(NEWT_SOURCE_DIR)/prerm $(NEWT_IPK_DIR)/CONTROL/prerm
	echo $(NEWT_CONFFILES) | sed -e 's/ /\n/g' > $(NEWT_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(NEWT_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
newt-ipk: $(NEWT_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
newt-clean:
	rm -f $(<FOO>_BUILD_DIR)/.built
	-$(MAKE) -C $(NEWT_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
newt-dirclean:
	rm -rf $(BUILD_DIR)/$(NEWT_DIR) $(NEWT_BUILD_DIR) $(NEWT_IPK_DIR) $(NEWT_IPK)

#
# Some sanity check for the package.
#
newt-check: $(NEWT_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $(NEWT_IPK)
