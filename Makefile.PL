use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::Goofey',
    'VERSION_FROM' => 'Net/Goofey.pm', # finds $VERSION
    'dist'         => {
                         COMPRESS => 'gzip -9f',
                         SUFFIX => 'gz',
                      },
);

sub MY::postamble {
   package MY;

   '

WEBDIR = /home/gossamer/websrc/docs/code
WEB_FILELIST = $(WEBDIR)/file-list

webdist: $(DISTVNAME).tar$(SUFFIX)
	@$(MOD_INSTALL) \
		read $(WEB_FILELIST)
		write $(WEB_FILELIST)
		$(DISTVNAME).tar$(SUFFIX) $(WEBDIR)/$(DISTNAME)/$(DISTVNAME).tar$(SUFFIX)
'
}

