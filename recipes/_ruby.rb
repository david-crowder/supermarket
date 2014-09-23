#
# Author:: Seth Vargo (<sethvargo@gmail.com>)
# Recipe:: ruby
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
  include_recipe 'supermarket::_apt'

  execute 'apt-get-update-ruby-only' do
    command "apt-get update -o Dir::Etc::sourcelist='sources.list.d/brightbox-ruby-ng-experimental-precise.list' -o Dir::Etc::sourceparts='-' -o APT::Get::List-Cleanup='0'"
    notifies :run, 'execute[apt-cache gencaches]'
    action :nothing
    ignore_failure true
  end

  execute 'add-apt-repository[ppa:brightbox]' do
    command 'add-apt-repository ppa:brightbox/ruby-ng-experimental'
    notifies :run, 'execute[apt-get-update-ruby-only]', :immediately
    not_if 'test -f /etc/apt/sources.list.d/brightbox-ruby-ng-experimental-precise.list'
  end
  
  package 'ruby2.0'
  package 'ruby2.0-dev'
when 'rhel'
  include_recipe 'supermarket::_yum'
  include_recipe 'supermarket::_git'

  execute 'ruby-build-2.1.3' do
    cwd "#{Chef::Config[:file_cache_path]}"
    command <<-EOH
      git clone https://github.com/sstephenson/ruby-build.git
      cd ruby-build
      ./install.sh
      ruby-build 2.1.3 /usr/local/ruby-2.1.3
    EOH
  end
end

%w{erb gem irb rake rdoc ri ruby testrb}.each do |rb|
  link "/usr/bin/#{rb}" do
    to "/usr/bin/#{rb}2.0"
  end
end

# the bundle contains gems that need to compile C extensions
package 'build-essential'

# Nokogiri requires XML
case node['platform_family']
when 'debian'
  package 'libxslt-dev'
  package 'libxml2-dev'
when 'rhel'
  package 'libxslt-devel'
  package 'libxml2-devel'
end

# SQLite3 requires development headers
case node['platform_family']
when 'debian'
  package 'libsqlite3-dev'
end

# `pg` requires development headers; this allows the application to deploy (bundle)
# when postgresql isn't running on the same node.
case node['platform_family']
when 'debian'
  package 'libpq-dev'
end

gem_package 'bundler' do
  version '>= 1.7.2'
end
