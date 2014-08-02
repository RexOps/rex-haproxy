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

  # check if somewhere in the backend configurations
  # send_client_ip is set to true (1)
  # if this is the case we need to set some iptables,
  # routing and sysctl rules.

  # these rules can also be found on:
  # http://blog.loadbalancer.org/configure-haproxy-with-tproxy-kernel-for-full-transparent-proxy/

  my ($is_send_client_ip) = grep { $_->{send_client_ip} } @{$backends};
  if ($is_send_client_ip) {
    sysctl "net.ipv4.conf.all.forwarding"     => 1;
    sysctl "net.ipv4.conf.all.send_redirects" => 1;

    run "iptables -t mangle -N DIVERT",
      unless => "iptables-save | grep ':DIVERT'";

    run "iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT",
      unless =>
      "iptables-save  | grep -- '-A PREROUTING -p tcp -m socket -j DIVERT'";

    run "iptables -t mangle -A DIVERT -j MARK --set-mark 777",
      unless =>
      "iptables-save  | grep -- '-A DIVERT -j MARK --set-xmark 0x309'";

    run "iptables -t mangle -A DIVERT -j ACCEPT",
      unless => "iptables-save | grep -- '-A DIVERT -j ACCEPT'";

    run "ip rule add fwmark 777 lookup 700",
      unless => "ip rule list | grep 0x309";

    run "ip route add local 0.0.0.0/0 dev lo table 700",
      unless => "ip route list table 700 | grep 'local default dev lo'";
  }
};

1;
