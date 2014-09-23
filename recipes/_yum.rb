#
# Author:: Nathan Cerny (<Nathan.Cerny@Cerner.com>)
# Recipe:: _yum
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

#TODO: Make this dynamic so it flexes on RHEL version
remote_file "#{Chef::Config[:file_cache_path]}/epel-release-6-8.noarch.rpm" do
  source 'http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm'
end

execute 'add-yum-epel' do
  command "rpm -Uvh #{Chef::Config[:file_cache_path]}/epel-release-6-8.noarch.rpm"
  not_if 'rpm -qa | grep epel'
end

execute 'yum makecache' do
  ignore_failure true
  action :nothing
end

