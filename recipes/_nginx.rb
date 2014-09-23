#
# Author:: Tristan O'Neil (<tristanoneil@gmail.com>)
# Recipe:: nginx
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
when 'rhel'
  include_recipe 'supermarket::_yum'
end

package 'nginx'

directory '/etc/nginx/sites-available' do
  recursive true
end

template '/etc/nginx/sites-available/default' do
  source 'supermarket.nginx.erb'
  notifies :reload, 'service[nginx]'
end

service 'nginx' do
  supports reload: true
  action [:enable, :start]
end

directory '/etc/logrotate.d'

cookbook_file "/etc/logrotate.d/nginx" do
  source "logrotate-nginx"
  owner "root"
  group "root"
  mode "0644"
end
