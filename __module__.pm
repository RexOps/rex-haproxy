#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=s sw=s tw=0:
# vim: set expandtab:

package HAProxy;

use Rex -feature => ['0.51'];
use Rex::Ext::ParamLookup;

my $packages = { centos => ["haproxy"], };

task "setup", make {
  my $package_name = param_lookup "package", $packages->{ lc operating_system };

  my $maxconn       = param_lookup "maxconn",       4096;
  my $haproxy_user  = param_lookup "haproxy_user",  "haproxy";
  my $haproxy_group = param_lookup "haproxy_group", "haproxy";

  my $contimeout = param_lookup "contimeout", 5000;
  my $clitimeout = param_lookup "clitimeout", 50000;
  my $srvtimeout = param_lookup "srvtimeout", 50000;

  my $frontends = param_lookup "frontends", [];
  my $backends  = param_lookup "backends",  [];

  pkg $package_name, ensure => present;

  file "/etc/haproxy/haproxy.cfg",
    content   => template("templates/haproxy.cfg.tpl"),
    owner     => "root",
    group     => "root",
    mode      => 633,
    on_change => make {
    service haproxy => "restart";
    };
};

1;
