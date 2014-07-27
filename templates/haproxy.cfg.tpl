global
  maxconn <%= $maxconn %>
  user <%= $haproxy_user %>
  group <%= $haproxy_group %>
  daemon
 
defaults
  log  global
  contimeout <%= $contimeout %>
  clitimeout <%= $clitimeout %>
  srvtimeout <%= $srvtimeout %>
 
<% for my $frontend (@{ $frontends }) { %>
frontend <%= $frontend->{name} %>
  bind <%= $frontend->{bind} %>
  default_backend <%= $frontend->{default_backend} %>
<% } %>


<% for my $backend (@{ $backends }) { %>
backend <%= $backend->{name} %>
  balance <%= $backend->{balance} %>
  <% if( exists $backend->{send_client_ip} && $backend->{send_client_ip} ) { %>
  source 0.0.0.0 usesrc clientip
  <% } %>
 
  mode <%= $backend->{mode} %>
  <% for my $line (@{ $backend->{$backend->{mode}} }) { %>
  <%= $line %>
  <% } %>
 
  # endpoints
  <% for my $server (@{ $backend->{server} }) { %>
  server <%= $server->{name} %> <%= $server->{dst} %> <%= $server->{options} %>
  <% } %>
<% } %>

frontend vs_stats :8081
  mode http
  default_backend stats_backend
 
backend stats_backend
  mode http
  stats enable
  stats uri /stats
  stats realm Stats\ Page
  stats auth admin:password
  stats admin if TRUE
