# -*- encoding: utf-8 -*-
#
# Author:: Benjamin W. Smith (<benjaminwarfield@just-another.net>)
#
# Copyright (C) 2013, Benjamin W. Smith
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

require 'kitchen'
require 'json'
require 'fog'

module Kitchen

  module Driver

    # Dreamcompute driver for Kitchen.
    #
    # @author Benjamin W. Smith <benjaminwarfield@just-another.net>
    class Dreamcompute < Kitchen::Driver::SSHBase
      default_config :availability_zone,  'iad-1'
      default_config :flavor_id,          'subsonic'
      default_config :groups,             ['default']

      default_config :dreamcompute_auth_url do |driver|
        ENV['OS_AUTH_URL']
      end

      default_config :dreamcompute_api_key  do |driver|
        ENV['OS_PASSWORD']
      end

      default_config :dreamcompute_username do |driver|
        ENV['OS_USERNAME']
      end

      required_config :dreamcompute_auth_url
      required_config :dreamcompute_api_key
      required_config :dreamcompute_username
      required_config :image_id


      def create(state)
        server = create_server
        state[:server_id] = server.id

        info("DreamCompute instance <#{state[:server_id]}> created.")

        server.wait_for { print "."; ready? } ; print "(server ready)"
        state[:hostname] = server.public_ip_address || server.private_ip_address
        wait_for_sshd(state[:hostname], config[:username]) ; print "(ssh ready)\n"
        debug("dreamcompute:create '#{state[:hostname]}'")
      rescue Fog::Errors::Error, Excon::Errors::Error => ex
        raise ActionFailed, ex.message
      end

      def destroy(state)
        return if state[:server_id].nil?

        server = connection.servers.get(state[:server_id])
        server.destroy unless server.nil?
        info("DreamCompute instance <#{state[:server_id]}> destroyed.")
        state.delete(:server_id)
        state.delete(:hostname)
      end

      private
      def connection
        Fog::Compute.new({
          :provider           => :openstack,
          :openstack_api_key  => config[:dreamhost_api_key],
          :openstack_username => config[:dreamhost_username],
          :openstack_auth_utl => "#{config[:dreamhost_auth_url]}/tokens"
        })
      end

      def create_server
        debug_server_config

        connection.servers.create(
          :availability_zone  => config[:availability_zone],
          :groups             => config[:groups],
          :flavor_id          => config[:flavor_id],
          :image_id           => config[:image_id],
          :key_name           => config[:ssh_key_id],
        )
      end

      def debug_server_config
        debug("dreamcompute:region '#{config[:region]}'")
        debug("dreamcompute:availability_zone '#{config[:availability_zone]}'")
        debug("dreamcompute:flavor_id '#{config[:flavor_id]}'")
        debug("dreamcompute:image_id '#{config[:image_id]}'")
        debug("dreamcompute:groups '#{config[:groups]}'")
        debug("dreamcompute:key_name '#{config[:ssh_key_id]}'")
      end


    end
  end
end
