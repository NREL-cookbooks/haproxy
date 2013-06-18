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
include_recipe "rbenv::system"
include_recipe "rsyslog"

include_recipe "haproxy::install_#{node['haproxy']['install_method']}"

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
rbenv_gem "haproxy_join"

directory "#{node['haproxy']['conf_dir']}/conf" do
  mode "0755"
  owner "root"
  group "root"
  recursive true
end

directory "#{node['haproxy']['conf_dir']}/conf/backend.d" do
  mode "0775"
  owner "root"
  group(node[:common_writable_group] || "root")
end

directory "#{node['haproxy']['conf_dir']}/conf/frontend.d" do
  mode "0775"
  owner "root"
  group(node[:common_writable_group] || "root")
end

template "#{node['haproxy']['conf_dir']}/conf/global.cfg" do
  source "global.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[haproxy]"
  variables(
    :defaults_options => haproxy_defaults_options,
    :defaults_timeouts => haproxy_defaults_timeouts
  )
end

template "#{node['haproxy']['conf_dir']}/conf/defaults.cfg" do
  source "defaults.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[haproxy]"
end

template "#{node['haproxy']['conf_dir']}/conf/frontend.cfg" do
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
