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

# sorted array of application data hashes with defaults filled in
apps = data_bag_items.map { |a| (data_bag_item(bag, a) || Hash.new).to_hash }
set_app_defaults(apps)
apps.sort! { |x, y| x['id'] <=> y['id'] }


# create databases and database users
Array(apps).each do |config|
end
