#
# Cookbook Name:: haproxy
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "iptables::haproxy_stats"
include_recipe "rbenv::global_version"
include_recipe "yum::epel"

include_recipe "rsyslog"

package "haproxy" do
  action :install
end

conf_dir = value_for_platform({
  ["ubuntu", "debian"] => { "default" => "default" },
  ["redhat", "centos", "fedora"] => { "default" => "sysconfig"}
})

template "/etc/#{conf_dir}/haproxy" do
  source "haproxy-default.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[haproxy]"
end

# Setup the /etc/haproxy directory according to how the haproxy_join helper
# script expects. This allows us to maintain separate configuration files that
# will get concatenated into the single configuration file that haproxy
# actually reads.
rbenv_gem "haproxy_join" do
  ruby_version node[:rbenv][:install_global_version]
end

directory "/etc/haproxy/conf" do
  mode "0755"
  owner "root"
  group "root"
  recursive true
end

directory "/etc/haproxy/conf/backend.d" do
  mode "0775"
  owner "root"
  group(node[:common_writable_group] || "root")
end

directory "/etc/haproxy/conf/frontend.d" do
  mode "0775"
  owner "root"
  group(node[:common_writable_group] || "root")
end

template "/etc/haproxy/conf/global.cfg" do
  source "global.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[haproxy]"
end

template "/etc/haproxy/conf/defaults.cfg" do
  source "defaults.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[haproxy]"
end

template "/etc/haproxy/conf/frontend.cfg" do
  source "frontend.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[haproxy]"
end

template "/etc/rsyslog.d/haproxy.conf" do
  source "rsyslog.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[rsyslog]"
end

logrotate_app "haproxy" do
  path [node[:haproxy][:log][:file]]
  frequency "daily"
  rotate node[:haproxy][:log][:rotate]
end

service "haproxy" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end
