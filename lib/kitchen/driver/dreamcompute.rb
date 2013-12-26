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

class ImageNotFound < StandardError; end
class FlavorNotFound < StandardError; end

module Kitchen

  module Driver

    # Dreamcompute driver for Kitchen.
    #
    # @author Benjamin W. Smith <benjaminwarfield@just-another.net>
    class Dreamcompute < Kitchen::Driver::SSHBase
      default_config :availability_zone,  'iad-1'
      default_config :flavor_id,          100
      default_config :groups,             ['default']
      default_config :ssl_v3_only,        false

      default_config :name do |driver|
        compute_unique_name
      end

      # TODO: Consider more DH contextual env vars
      # These are the defaults from the openstack rc
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
      required_config :image_name
      required_config :flavor_name

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
        ssl_v3_only if config[:ssl_v3_only]
        return if state[:server_id].nil?

        server = connection.servers.get(state[:server_id])
        server.destroy unless server.nil?
        info("DreamCompute instance <#{state[:server_id]}> destroyed.")
        state.delete(:server_id)
        state.delete(:hostname)
      end

      private
      def connection
        @connection ||= Fog::Compute.new({
          :provider           => :openstack,
          :openstack_api_key  => config[:dreamcompute_api_key],
          :openstack_username => config[:dreamcompute_username],
          :openstack_auth_url => "#{config[:dreamcompute_auth_url]}/tokens"
        })
      end

      def compute_unique_name
        "test-kitchen-#{(0...8).map { (65 + rand(26)).chr }.join}"
      end

      def ssl_v3_only
        require 'rubygems'
        require 'excon'
        Excon.defaults[:ssl_version] = 'SSLv3'
      end

      def create_server
        debug_server_config

        flavor_ref = find_flavor_id(active_flavors,
                                    config[:flavor_name]) || config[:flavor_id]

        image_ref = find_image_id(active_images, config[:image_name])

        connection.servers.create(
          :availability_zone  => config[:availability_zone],
          :groups             => config[:groups],
          :name               => config[:name],
          :flavor_ref         => flavor_ref,
          :image_ref          => image_ref,
          :key_name           => config[:ssh_key_id],
        )
      end

      def debug_server_config
        debug("dreamcompute:name '#{config[:name]}'")
        debug("dreamcompute:region '#{config[:region]}'")
        debug("dreamcompute:availability_zone '#{config[:availability_zone]}'")
        debug("dreamcompute:flavor_id '#{config[:flavor_id]}'")
        debug("dreamcompute:image_id '#{config[:image_id]}'")
        debug("dreamcompute:groups '#{config[:groups]}'")
        debug("dreamcompute:key_name '#{config[:ssh_key_id]}'")
      end

      def active_images
        @connection.images.select { |i| i.status == 'ACTIVE' }
      end

      def active_flavors
        @connection.flavors.each { |f| (!f.disabled && f.is_public) }
      end

      def find_image_id(images, image_name)
        images.select { |i| i.name == image_name }.pop or raise ImageNotFound
      end

      def find_flavor_id(flavors, flavor_name)
        flavors.select { |f| f.name == flavor_name }.pop or raise FlavorNotFound
      end

    end
  end
end
