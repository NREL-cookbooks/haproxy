maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs and configures haproxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "0.8.3"

recipe "haproxy", "Installs and configures haproxy"
recipe "haproxy::app_lb", "Installs and configures haproxy by searching for nodes of a particular role"

%w{ debian ubuntu }.each do |os|
  supports os
end

depends "iptables"
depends "logrotate"
depends "rsyslog"
depends "rbenv"
depends "yum"
