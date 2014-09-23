#
# Author:: Tristan O'Neil (<tristanoneil@gmail.com>)
# Recipe:: runit
#
# Copyright 2014 Chef Software, Inc.
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

case node['platform_family']
when 'debian'
  package 'runit'
when 'rhel'
  #From the runit cookbook
  packages = %w{autoconf bison flex gcc gcc-c++ kernel-devel make m4 patch rpm-build rpmdevtools tar gzip}
  packages.each do |p|
    package p
  end

  if node['platform_version'].to_i >= 6
    package 'glibc-static'
  else
    package 'buildsys-macros'
  end

  rpm_installed = "rpm -qa | grep -q '^runit'"
  remote_file "#{Chef::Config[:file_cache_path]}/runit-2.1.1.tar.gz" do
    source "https://github.com/hw-cookbooks/runit/blob/v1.5.10/files/default/runit-2.1.1.tar.gz?raw=true"
    not_if rpm_installed
    notifies :run, 'bash[rhel_build_install]', :immediately
  end
  
  bash 'rhel_build_install' do
    user 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-EOH
      tar xzf runit-2.1.1.tar.gz
      cd runit-2.1.1
      ./build.sh
      rpm_root_dir=`rpm --eval '%{_rpmdir}'`
      rpm -ivh "${rpm_root_dir}/runit-2.1.1.rpm"
    EOH
    action :run
    not_if rpm_installed
  end
end

directory '/etc/service' do
  mode '0755'
  recursive true
end

%w(unicorn sidekiq).each do |service|
  directory "/etc/sv/#{service}" do
    mode '0755'
    recursive true
  end

  directory "/etc/sv/#{service}/log" do
    mode '0755'
    recursive true
  end

  directory "/var/log/#{service}" do
    mode '0755'
    recursive true
  end

  template "/etc/sv/#{service}/run" do
    source "#{service}.sv.erb"
    mode '0755'
  end

  file "/etc/sv/#{service}/log/run" do
    content "#!/bin/sh\nexec svlogd -tt /var/log/#{service}\n"
    mode '0755'
  end

  link "/etc/service/#{service}" do
    to "/etc/sv/#{service}"
  end
end

service 'unicorn' do
  restart_command 'sv 2 unicorn'
end

service 'sidekiq' do
  restart_command 'sv t sidekiq'
end
