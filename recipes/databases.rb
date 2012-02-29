#
# Cookbook Name:: fanfare
# Recipe:: databases
#
# Copyright 2012, Fletcher Nichol
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

include_recipe 'fanfare'

bag   = 'fanfare_apps'
data_bag_items = begin
  data_bag(bag)
rescue => ex
  Chef::Log.warn("Data bag #{bag} not found (#{ex}), so skipping")
  []
end

# array of application data hashes
apps = data_bag_items.map { |a| (data_bag_item(bag, a) || Hash.new).to_hash }
# select all apps that define require a db in my cluster for my database type
apps = apps.select do |app|
  app['db_info'] = Chef::Fanfare::DbInfo.new(app, node)

  app['db'] &&
  node.role?("cluster_#{app['cluster']}") &&
  node.role?("facet_#{app['db_info'].type}_node")
end
# set defaults for apps
set_app_defaults(apps)
# deterministically sort the apps
apps.sort! { |x, y| x['id'] <=> y['id'] }

# install mysql and/or pg gem if required by at least one app
apps.map { |a| a['db_info'].gem }.uniq.each { |gem| gem_package gem }

# create databases and database users
Array(apps).each do |app|
  create_app_db       app['db_info']
  create_app_db_user  app['db_info']
end
