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
      default_config :username,           'dhc-user'

      default_config :server_name do |driver|
        driver.compute_unique_name
      end

      default_config :dreamcompute_auth_url do |driver|
        ENV['OS_AUTH_URL']
      end

      default_config :dreamcompute_api_key  do |driver|
        ENV['OS_PASSWORD']
      end

      default_config :dreamcompute_username do |driver|
        ENV['OS_USERNAME']
      end

      default_config :dreamcompute_tenant_name do |driver|
        ENV['OS_TENANT_NAME']
      end

      required_config :dreamcompute_auth_url
      required_config :dreamcompute_api_key
      required_config :dreamcompute_username
      required_config :dreamcompute_tenant_name
      required_config :image_name
      required_config :flavor_name

      def create(state)
        ssl_v3_only if config[:ssl_v3_only]
        server = create_server
        state[:server_id] = server.id

        info("DreamCompute instance <#{state[:server_id]}> created.")
        info('Waiting for server to be available')
        server.wait_for { print "."; ready? } ; print "(server ready)"

        # WIP
        # associate_floating_ip(server)

        state[:hostname] = server.public_ip_address || server.private_ip_address

        info("Waiting for ssh on #{state[:hostname]} with #{config[:username]}")

        wait_for_sshd(state[:hostname], config[:username], {:ipv6 => true}) ; print "(ssh ready)\n"
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

      def connection
        @connection ||= Fog::Compute::OpenStack.new({
          :openstack_api_key  => config[:dreamcompute_api_key],
          :openstack_username => config[:dreamcompute_username],
          :openstack_tenant   => config[:dreamcompute_tenant_name],
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

      def create_volume(image_id)
        volume_service = Fog::Volume::OpenStack.new({
          :openstack_api_key  => config[:dreamcompute_api_key],
          :openstack_username => config[:dreamcompute_username],
          :openstack_tenant   => config[:dreamcompute_tenant_name],
          :openstack_auth_url => "#{config[:dreamcompute_auth_url]}/tokens"
        })

        volume_service.volumes.create(size: 80,
                                      display_name: compute_unique_name,
                                      display_description: 'Test Kitchen Volume',
                                      imageRef: image_id)
      end

      def create_server
        config[:flavor_id] = find_flavor_id(active_flavors,
                                    config[:flavor_name]) || config[:flavor_id]
        config[:image_id] = find_image_id(active_images, config[:image_name])

        new_volume = create_volume(config[:image_id])

        info('Waiting for new volume to be available')
        new_volume.wait_for { print '.'; status == 'available' }

        block_device_options = {
          :volume_name           => new_volume.display_name,
          :device_name           => 'vda',
          :volume_id             => new_volume.id,
          :delete_on_termination => true
        }

        connection.servers.create(
          :availability_zone    => config[:availability_zone],
          :groups               => config[:groups],
          :name                 => config[:server_name],
          :flavor_ref           => config[:flavor_id],
          :image_ref            => config[:image_id],
          :key_name             => config[:ssh_key_id],
          :block_device_mapping => block_device_options
        )
      end

      def available_floating_ips
        connection.addresses.find_all { |address| address.instance_id.nil? }
      end

      def associate_floating_ip(server)
        address = available_floating_ips.first.ip
        server.associate_address(address)
        (server.addresses['public'] ||= []) << { 'version' => 4, 'addr' => address }
      end

      def active_images
        connection.images.select { |i| i.status == 'ACTIVE' }
      end

      def active_flavors
        connection.flavors.each { |f| (!f.disabled && f.is_public) }
      end

      def find_image_id(images, image_name)
        images.select { |i| i.name == image_name }.pop.id or raise ImageNotFound
      end

      def find_flavor_id(flavors, flavor_name)
        flavors.select { |f| f.name == flavor_name }.pop.id or raise FlavorNotFound
      end

    end
  end
end
