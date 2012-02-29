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
          app['user']           ||= app['id']
          app['name']           ||= app['id']
          app['type']           ||= node['fanfare']['default_app_type']
          app['env']            ||= Hash.new
          app['vhost_template'] ||= "fanfare::nginx_vhost.conf.erb"
          app['http']           ||= Hash.new
          app['http']['http_port']   ||= 80
          app['http']['https_port']  ||= 443

          app['http']['ssl_certificate']      ||= "#{app['name']}.crt"
          app['http']['ssl_certificate_key']  ||= "#{app['name']}.key"

          deploy_to = "#{node['fanfare']['root_path']}/#{app['name']}"
          app['http']['upstream_server'] ||=
            "unix:#{deploy_to}/shared/sockets/unicorn.sock"

          if app['env']['PORT'].nil?
            app['env']['PORT'] = http_port.to_s
            http_port += 100
          end

          if app['type'] == "rails" && app['env']['RAILS_ENV'].nil?
            app['env']['RAILS_ENV'] = "production"
          elsif app['type'] == "rack" && app['env']['RACK_ENV'].nil?
            app['env']['RACK_ENV'] = "production"
          end
        end
      end

      def set_app_env_path(app, user)
        if app['env']['PATH'].nil?
          app['env']['PATH'] = node['fanfare']['default_env_path']

          if node['rbenv'] && node['rbenv']['root_path']
            rbenv_root = node['rbenv']['root_path']

            app['env']['PATH'] = [
              "#{user['home']}/.rbenv/shims:#{user['home']}/.rbenv/bin",
              "#{rbenv_root}/shims:#{rbenv_root}/bin",
              app['env']['PATH']
            ].join(':')
          end

          app['env']['PATH'] = [
            "#{node['fanfare']['root_path']}/#{app['name']}/current/bin",
            app['env']['PATH']
          ].join(':')
        end
      end

      def set_app_env_database_url(app, user)
        if app['db'] && app['env']['DATABASE_URL'].nil?
          db = Chef::Fanfare::DbInfo.new(app, node)

          app['env']['DATABASE_URL'] = [
            "#{db.adapter}://",
            "#{db.user_username}:#{db.user_password}@",
            "#{db.host}/#{db.database}"
          ].join
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

      def create_app_db(db)
        database db.database do
          connection  db.connection_info
          provider    db.provider
          action      :create
        end
      end

      def create_app_db_user(db)
        database_user db.user_username do
          connection      db.connection_info
          password        db.user_password
          database_name   db.database  if db.type == "mysql"
          provider        db.user_provider
          action          :create
        end

        database_user db.user_username do
          connection      db.connection_info
          password        db.user_password
          database_name   db.database
          privileges      [ :all ]
          host            "%"   if db.type == "mysql"
          provider        db.user_provider
          action          :grant
        end
      end

      def create_app_vhost(app, user)
        template_cookbook, template_source = app['vhost_template'].split('::')

        template "#{node['nginx']['dir']}/sites-available/#{app['name']}.conf" do
          cookbook    template_cookbook
          source      template_source
          owner       "root"
          mode        "0644"
          variables({
            :app              => app,
            :deploy_to_path   => "#{node['fanfare']['root_path']}/#{app['name']}",
            :log_path         => node['nginx']['log_dir'],
            :ssl_certs_path   => node['fanfare']['http']['ssl_certs_path'],
            :ssl_private_path => node['fanfare']['http']['ssl_private_path']
          })

          not_if      { template_cookbook == "none" }
        end

        nginx_site "#{app['name']}.conf"
      end
    end
  end
end
