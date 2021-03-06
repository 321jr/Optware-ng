###########################################################
#
# libgmp
#
###########################################################

#
# LIBGMP_VERSION, LIBGMP_SITE and LIBGMP_SOURCE define
# the upstream location of the source code for the package.
# LIBGMP_DIR is the directory which is created when the source
# archive is unpacked.
# LIBGMP_UNZIP is the command used to unzip the source.
# It is usually "zcat" (for .gz) or "bzcat" (for .bz2)
#
# You should change all these variables to suit your package.
# Please make sure that you add a description, and that you
# list all your packages' dependencies, seperated by commas.
# 
# If you list yourself as MAINTAINER, please give a valid email
# address, and indicate your irc nick if it cannot be easily deduced
# from your name or email address.  If you leave MAINTAINER set to
# "NSLU2 Linux" other developers will feel free to edit.
#
LIBGMP_SITE=ftp://ftp.gnu.org/gnu/gmp
LIBGMP_VERSION=6.1.2
LIBGMP_SOURCE=gmp-$(LIBGMP_VERSION).tar.bz2
LIBGMP_DIR=gmp-$(LIBGMP_VERSION)
LIBGMP_UNZIP=bzcat
LIBGMP_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
LIBGMP_DESCRIPTION=GNU Multiple Precision Arithmetic Library.
LIBGMP_SECTION=misc
LIBGMP_PRIORITY=optional
LIBGMP_DEPENDS=
LIBGMP_SUGGESTS=
LIBGMP_CONFLICTS=

#
# LIBGMP_IPK_VERSION should be incremented when the ipk changes.
#
LIBGMP_IPK_VERSION=1

#
# LIBGMP_CONFFILES should be a list of user-editable files
#LIBGMP_CONFFILES=$(TARGET_PREFIX)/etc/libgmp.conf $(TARGET_PREFIX)/etc/init.d/SXXlibgmp

#
# LIBGMP_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
#LIBGMP_PATCHES=$(LIBGMP_SOURCE_DIR)/configure.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
LIBGMP_CPPFLAGS=
LIBGMP_LDFLAGS=

#
# LIBGMP_BUILD_DIR is the directory in which the build is done.
# LIBGMP_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# LIBGMP_IPK_DIR is the directory in which the ipk is built.
# LIBGMP_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
LIBGMP_BUILD_DIR=$(BUILD_DIR)/libgmp
LIBGMP_HOST_BUILD_DIR=$(HOST_BUILD_DIR)/libgmp
LIBGMP_SOURCE_DIR=$(SOURCE_DIR)/libgmp
LIBGMP_IPK_DIR=$(BUILD_DIR)/libgmp-$(LIBGMP_VERSION)-ipk
LIBGMP_IPK=$(BUILD_DIR)/libgmp_$(LIBGMP_VERSION)-$(LIBGMP_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: libgmp-source libgmp-unpack libgmp libgmp-stage libgmp-ipk libgmp-clean libgmp-dirclean libgmp-check libgmp-host-stage

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(LIBGMP_SOURCE):
	$(WGET) -P $(@D) $(LIBGMP_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
libgmp-source: $(DL_DIR)/$(LIBGMP_SOURCE) $(LIBGMP_PATCHES)

#
# This target unpacks the source code in the build directory.
# If the source archive is not .tar.gz or .tar.bz2, then you will need
# to change the commands here.  Patches to the source code are also
# applied in this target as required.
#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <bar>-stage <baz>-stage").
#
# If the package uses  GNU libtool, you should invoke $(PATCH_LIBTOOL) as
# shown below to make various patches to it.
#
$(LIBGMP_BUILD_DIR)/.configured: $(DL_DIR)/$(LIBGMP_SOURCE) $(LIBGMP_PATCHES) make/libgmp.mk
#	$(MAKE) <bar>-stage <baz>-stage
	rm -rf $(BUILD_DIR)/$(LIBGMP_DIR) $(@D)
	$(LIBGMP_UNZIP) $(DL_DIR)/$(LIBGMP_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	if test -n "$(LIBGMP_PATCHES)" ; \
		then cat $(LIBGMP_PATCHES) | \
		$(PATCH) -d $(BUILD_DIR)/$(LIBGMP_DIR) -p0 ; \
	fi
	if test "$(BUILD_DIR)/$(LIBGMP_DIR)" != "$(@D)" ; \
		then mv $(BUILD_DIR)/$(LIBGMP_DIR) $(@D) ; \
	fi
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(LIBGMP_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(LIBGMP_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=$(TARGET_PREFIX) \
		--disable-nls \
		--disable-static \
	)
	$(PATCH_LIBTOOL) $(@D)/libtool
	touch $@

libgmp-unpack: $(LIBGMP_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(LIBGMP_BUILD_DIR)/.built: $(LIBGMP_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D)
	touch $@

#
# This is the build convenience target.
#
libgmp: $(LIBGMP_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
$(LIBGMP_BUILD_DIR)/.staged: $(LIBGMP_BUILD_DIR)/.built
	rm -f $@ $(STAGING_LIB_DIR)/libgmp.*
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install
	rm -f $(STAGING_LIB_DIR)/libgmp.la
	touch $@

libgmp-stage: $(LIBGMP_BUILD_DIR)/.staged

$(LIBGMP_HOST_BUILD_DIR)/.staged: host/.configured $(DL_DIR)/$(LIBGMP_SOURCE) make/libgmp.mk
	rm -rf $(HOST_BUILD_DIR)/$(LIBGMP_DIR) $(@D)
	$(LIBGMP_UNZIP) $(DL_DIR)/$(LIBGMP_SOURCE) | tar -C $(HOST_BUILD_DIR) -xvf -
	if test "$(HOST_BUILD_DIR)/$(LIBGMP_DIR)" != "$(@D)" ; \
		then mv $(HOST_BUILD_DIR)/$(LIBGMP_DIR) $(@D) ; \
	fi
	(cd $(@D); \
		CFLAGS="-fPIC" \
		./configure \
		--prefix=$(HOST_STAGING_PREFIX) \
		--disable-nls \
		--disable-shared; \
	)
	$(MAKE) -C $(@D)
	$(MAKE) install -C $(@D)
	touch $@

libgmp-host-stage: $(LIBGMP_HOST_BUILD_DIR)/.staged

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/libgmp
#
$(LIBGMP_IPK_DIR)/CONTROL/control:
	@$(INSTALL) -d $(@D)
	@rm -f $@
	@echo "Package: libgmp" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(LIBGMP_PRIORITY)" >>$@
	@echo "Section: $(LIBGMP_SECTION)" >>$@
	@echo "Version: $(LIBGMP_VERSION)-$(LIBGMP_IPK_VERSION)" >>$@
	@echo "Maintainer: $(LIBGMP_MAINTAINER)" >>$@
	@echo "Source: $(LIBGMP_SITE)/$(LIBGMP_SOURCE)" >>$@
	@echo "Description: $(LIBGMP_DESCRIPTION)" >>$@
	@echo "Depends: $(LIBGMP_DEPENDS)" >>$@
	@echo "Suggests: $(LIBGMP_SUGGESTS)" >>$@
	@echo "Conflicts: $(LIBGMP_CONFLICTS)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/sbin or $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/{lib,include}
# Configuration files should be installed in $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/etc/libgmp/...
# Documentation files should be installed in $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/doc/libgmp/...
# Daemon startup scripts should be installed in $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/S??libgmp
#
# You may need to patch your application to make it use these locations.
#
$(LIBGMP_IPK): $(LIBGMP_BUILD_DIR)/.built
	rm -rf $(LIBGMP_IPK_DIR) $(BUILD_DIR)/libgmp_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(LIBGMP_BUILD_DIR) DESTDIR=$(LIBGMP_IPK_DIR) install-strip
	$(STRIP_COMMAND) $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/lib/libgmp.so.*
#	$(INSTALL) -d $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/etc/
#	$(INSTALL) -m 644 $(LIBGMP_SOURCE_DIR)/libgmp.conf $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/etc/libgmp.conf
#	$(INSTALL) -d $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/etc/init.d
#	$(INSTALL) -m 755 $(LIBGMP_SOURCE_DIR)/rc.libgmp $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/SXXlibgmp
	rm -f $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/share/info/dir $(LIBGMP_IPK_DIR)$(TARGET_PREFIX)/lib/libgmp.la
	$(MAKE) $(LIBGMP_IPK_DIR)/CONTROL/control
#	$(INSTALL) -m 755 $(LIBGMP_SOURCE_DIR)/postinst $(LIBGMP_IPK_DIR)/CONTROL/postinst
#	$(INSTALL) -m 755 $(LIBGMP_SOURCE_DIR)/prerm $(LIBGMP_IPK_DIR)/CONTROL/prerm
	echo $(LIBGMP_CONFFILES) | sed -e 's/ /\n/g' > $(LIBGMP_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(LIBGMP_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
libgmp-ipk: $(LIBGMP_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
libgmp-clean:
	rm -f $(LIBGMP_BUILD_DIR)/.built
	-$(MAKE) -C $(LIBGMP_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
libgmp-dirclean:
	rm -rf $(BUILD_DIR)/$(LIBGMP_DIR) $(LIBGMP_BUILD_DIR) $(LIBGMP_IPK_DIR) $(LIBGMP_IPK)

#
# Some sanity check for the package.
#
libgmp-check: $(LIBGMP_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $^
