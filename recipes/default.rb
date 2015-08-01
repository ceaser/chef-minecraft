#
# Cookbook Name:: minecraft
# Recipe:: default
#
# Copyright 2013, Greg Fitzgerald
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "java::#{node['java']['install_flavor']}"
include_recipe 'minecraft::user'


jar_name = minecraft_file(node['minecraft']['url'])

directory node['minecraft']['install_dir'] do
  recursive true
  owner node['minecraft']['user']
  group node['minecraft']['group']
  mode 0755
  action :create
end

remote_file "#{node['minecraft']['install_dir']}/#{jar_name}" do
  source node['minecraft']['url']
  checksum node['minecraft']['checksum']
  owner node['minecraft']['user']
  group node['minecraft']['group']
  mode 0644
  action :create_if_missing
end

include_recipe "minecraft::#{node['minecraft']['install_type']}"

template "#{node['minecraft']['install_dir']}/server.properties" do
  owner node['minecraft']['user']
  group node['minecraft']['group']
  mode 0644
  action :create
  case node['minecraft']['init_style']
  when 'runit'
    notifies :restart, 'runit_service[minecraft]', :delayed if node['minecraft']['autorestart']
  when 'upstart'
    notifies :restart, 'service[minecraft]', :delayed if node['minecraft']['autorestart']
  end
end

%w(ops banned-ips banned-players white-list).each do |f|
  file "#{node['minecraft']['install_dir']}/#{f}.txt" do
    owner node['minecraft']['user']
    group node['minecraft']['group']
    mode 0644
    action :create
    content node['minecraft'][f].join("\n") + "\n"
    case node['minecraft']['init_style']
    when 'runit'
      notifies :restart, 'runit_service[minecraft]', :delayed if node['minecraft']['autorestart']
    when 'upstart'
      notifies :restart, 'service[minecraft]', :delayed if node['minecraft']['autorestart']
    end
  end
end

file "#{node['minecraft']['install_dir']}/eula.txt" do
  content "eula=#{node['minecraft']['accept_eula']}\n"
  mode 0644
  action :create

  case node['minecraft']['init_style']
  when 'runit'
    notifies :restart, 'runit_service[minecraft]', :delayed if node['minecraft']['autorestart']
  when 'upstart'
    notifies :restart, 'service[minecraft]', :delayed if node['minecraft']['autorestart']
  end
end

case node['minecraft']['init_style']
when 'runit'
  include_recipe 'runit'
  include_recipe 'minecraft::service'
end

service "minecraft" do
  action :nothing
  only_if { node['minecraft']['init_style'] == 'upstart' }
end

template '/etc/init/minecraft.conf' do
  source 'init_minecraft.erb'
  owner 'root'
  group 'root'
  mode 0644
  notifies :restart, 'service[minecraft]', :delayed if node['minecraft']['autorestart']
only_if { node['minecraft']['init_style'] == 'upstart' }
end

service "minecraft" do
  provider Chef::Provider::Service::Upstart
  action [ :enable, :start ]
  only_if { node['minecraft']['init_style'] == 'upstart' }
end
