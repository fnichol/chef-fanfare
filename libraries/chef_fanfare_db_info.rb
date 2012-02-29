#
# Cookbook Name:: fanfare
# Library:: Chef::Fanfare::DbInfo
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

      def gem
        if type == "mysql"
          "mysql"
        else
          "pg"
        end
      end

      def provider
        Chef::Provider::Database.const_get(
          type.capitalize.to_sym)
      end

      def user_provider
        Chef::Provider::Database.const_get(
          type.capitalize.concat("User").to_sym)
      end

      def connection_info
        send("#{type}_db_connection_info")
      end

      private

      def postgresql_db_connection_info
        { :host => "localhost",
          :username => "postgres",
          :password => node['postgresql']['password']['postgres']
        }
      end

      def mysql_db_connection_info
        { :host => "localhost",
          :username => "root",
          :password => node['mysql']['server_root_password']
        }
      end
    end
  end
end
