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
    class DbInfo
      attr_reader :config
      attr_reader :node

      def initialize(config, node)
        @config = config
        @node = node
      end

      def adapter
        config['db']['adapter'] || config['db']['type'] ||
          node['fanfare']['default_db_type']
      end

      def type
        config['db']['type'] || adapter.sub(/^mysql2/, 'mysql')
      end

      def user_username
        if config['db']['username']
          config['db']['username']
        elsif type == "mysql"
          # mysql has a limit on length of usernames, ugh
          # http://twitter.com/fnichol/status/169198445687611393
          name_bits = config['name'].sub(/staging$/, 'stg').
            sub(/production$/, 'prod'). sub(/development$/, 'dev').
            rpartition(/_/)
          name_bits[0] = name_bits[0].slice(
            0...(15 - (name_bits[1].length + name_bits[2].length)))
          result = name_bits.join
          ::Chef::Log.info("MySQL database username of '#{config['name']}' " +
                           "has been shortened to '#{result}'")
          result
        else
          config['name']
        end
      end

      def user_password
        config['db']['password']
      end

      def host
        config['db']['host']
      end

      def port
        if config['db']['port']
          config['db']['port']
        elsif type == "mysql"
          "3306"
        elsif type == "postgresql"
          "5432"
        end
      end

      def database
        config['db']['database'] || config['name']
      end
    end

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

          if app['db'] && app['env']['DATABASE_URL'].nil?
            db = Chef::Fanfare::DbInfo.new(app, node)

            app['env']['DATABASE_URL'] = [
              "#{db.adapter}://",
              "#{db.user_username}:#{db.user_password}@",
              "#{db.host}/#{db.database}"
            ].join
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
          mode    "0664"
          variables({ :config => config })
        end
      end

      def create_database_yaml(config, user)
        root_path = node['fanfare']['root_path']
        app_home  = "#{root_path}/#{config['name']}"

        cookbook_file "#{app_home}/shared/config/database.yml" do
          source  "database.yml"
          owner   user['id']
          group   user['gid']
          mode    "0664"

          not_if  { config['db'].nil? }
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
