#
# Cookbook Name:: fanfare
# Library:: Chef::Fanfare::RecipeHelpers
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
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

class Chef
  module Fanfare
    module RecipeHelpers
      def set_app_defaults(apps)
        http_port = node['fanfare']['first_http_port']

        apps.each do |app|
          app['user'] ||= app['id']
          app['name'] ||= app['id']
          app['type'] ||= node['fanfare']['default_app_type']
          app['env']  ||= Hash.new

          if app['env']['PORT'].nil?
            app['env']['PORT'] = http_port.to_s
            http_port += 100
          end

          if app['type'] == "rails" && app['env']['RAILS_ENV'].nil?
            app['env']['RAILS_ENV'] = "production"
          end
        end
      end

      def create_app_user(user)
        u = begin
          # look up the user's data bag item
          data_bag_item(node['user']['data_bag'], name.gsub(/[.]/, '-'))
        rescue => ex
          # if user isn't defined in a data bag, create a default one
          { 'username' => user }
        end
        username  = u['username'] || u['id']
        gid       = u['gid'] || username
        user_home = u['home'] || "#{node['user']['home_root']}/#{username}"

        user_account username do
          %w{comment uid gid home shell password system_user manage_home create_group
              ssh_keys ssh_keygen}.each do |attr|
            send(attr, u[attr]) if u[attr]
          end
          action u['action'].to_sym if u['action']
        end

        { 'id' => username, 'gid' => gid, 'home' => user_home }
      end

      def create_app_user_dotfiles(user)
        template "#{user['home']}/.bashrc" do
          source  "bashrc.erb"
          owner   user['id']
          group   user['gid']
          mode    "0644"
        end
      end

      def create_app_user_foreman_templates(user)
        directory "#{user['home']}/.foreman/templates" do
          owner       user['id']
          group       user['gid']
          mode        "2755"
          recursive   true
        end

        cookbook_file "#{user['home']}/.foreman/templates/run.erb" do
          source  "foreman/runit/run.erb"
          owner   user['id']
          group   user['gid']
          mode    "0644"
        end

        cookbook_file "#{user['home']}/.foreman/templates/log_run.erb" do
          source  "foreman/runit/log_run.erb"
          owner   user['id']
          group   user['gid']
          mode    "0644"
        end
      end

      def create_app_user_runit_service(user)
        directory "#{user['home']}/service" do
          owner       user['id']
          group       user['gid']
          mode        "2755"
          recursive   true
        end

        directory "/var/log/user-#{user['id']}" do
          owner       "root"
          group       "root"
          mode        "755"
          recursive   true
        end

        runit_service "user-#{user['id']}" do
          template_name   "user"
          options({ :user => user['id'] })
        end
      end

      def create_app_dirs(config, user)
        root_path = node['fanfare']['root_path']
        app_home  = "#{root_path}/#{config['name']}"

        directory root_path

        [app_home, "#{app_home}/shared", "#{app_home}/shared/config"].each do |dir|
          directory dir do
            owner       user['id']
            group       user['gid']
            mode        "2775"
            recursive   true
          end
        end
      end

      def create_env_file(config, user)
        root_path = node['fanfare']['root_path']
        app_home  = "#{root_path}/#{config['name']}"

        template "#{app_home}/shared/env" do
          source  "env.erb"
          owner   user['id']
          group   user['gid']
          mode    "0400"
          variables({ :config => config })
        end
      end

      def create_app_dir_symlink(config, user)
        link "#{user['home']}/#{config['name']}" do
          to      "#{node['fanfare']['root_path']}/#{config['name']}"
          owner   user['id']
          group   user['gid']
        end
      end
    end
  end
end
