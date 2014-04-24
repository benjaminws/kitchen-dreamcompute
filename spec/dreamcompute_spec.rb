require_relative 'spec_helper'

describe Kitchen::Driver::Dreamcompute do

  let(:logged_output) { StringIO.new }
  let(:logger) { Logger.new(logged_output) }
  let(:config) { Hash.new }
  let(:state) { Hash.new }

  let(:driver) do
    driver = Kitchen::Driver::Dreamcompute.new(config)
    driver.instance = double(:name => 'danger',
                             :logger => logger,
                             :to_s => 'instance')
    return driver
  end

  before(:each) do
    ENV['OS_AUTH_URL'] = 'http://localhost'
    ENV['OS_PASSWORD'] = 'test_password'
    ENV['OS_USERNAME'] = 'test_user'
  end

  describe '#initialize' do

    context 'with default options' do
      it 'will prefer the iad-1 availability zone' do
        expect(driver[:availability_zone]).to eq('iad-1')
      end

      it 'will prefer flavor_id 100' do
        expect(driver[:flavor_id]).to eq(100)
      end

      it 'will prefer default group' do
        expect(driver[:groups]).to match_array(['default'])
      end

      it 'will not prefer ssl version 3 only' do
        expect(driver[:ssl_v3_only]).to eq(false)
      end

      it 'will generate a server_name' do
        expect(driver[:server_name]).not_to be(nil)
      end

      it 'will derive dreamcompute_auth_url from the env' do
        expect(driver[:dreamcompute_auth_url]).to eq('http://localhost')
      end

      it 'will derive dreamcompute_api_key from the env' do
        expect(driver[:dreamcompute_api_key]).to eq('test_password')
      end

      it 'will derive dreamcompute_username from the env' do
        expect(driver[:dreamcompute_username]).to eq('test_user')
      end

      it 'will prefer root as the default user' do
        expect(driver[:username]).to eq('dhc-user')
      end

      it 'will have a nil image_name' do
        expect(driver[:image_name]).to eq(nil)
      end

      it 'will have a nil image_name' do
        expect(driver[:image_name]).to eq(nil)
      end
    end

    context 'with overriden options' do
      let(:config) do
        {
          availability_zone: 'iad-2',
          flavor_id: 30,
          groups: ['not_default'],
          ssl_v3_only: true,
          server_name: 'blah-test',
          dreamcompute_auth_url: 'http://127.0.0.1:8080',
          dreamcompute_api_key: 'test_api_key',
          dreamcompute_username: 'test_username',
          dreamcompute_tenant_name: 'test',
          image_name: 'image1',
          flavor_name: 'flavor1',
          username: 'toor'
        }
      end

      let(:configured_driver) do
        driver = Kitchen::Driver::Dreamcompute.new(config)
        driver.instance = double(:name => 'danger',
                                 :logger => logger,
                                 :to_s => 'instance')
        return driver
      end

      it 'will use the appropriate configuration values' do
        driver = configured_driver
        config.each do |key, value|
          expect(driver[key]).to eq(value)
        end
      end
    end
  end

  describe '#compute_unique_name' do
    it 'will generate a server_name that will not be nil' do
      expect(driver[:server_name]).not_to be(nil)
    end

    it 'will generate a server_name that starts with test-kitchen' do
      expect(driver[:server_name]).to start_with('test-kitchen')
    end
  end

  describe '#create' do
    let(:server_double) do
      double(:id => 'abcd1234',
             :wait_for => true,
             :public_ip_address => '1.2.3.4')
    end

    let(:configured_driver) do
      driver = Kitchen::Driver::Dreamcompute.new(config)
      driver.instance = double(:name => 'test-kitchen-abcd1234',
                               :logger => logger,
                               :to_s => 'instance')
      driver.stub(:compute_unique_name).and_return('test-kitchen-abcd1234')
      driver.stub(:create_server).and_return(server_double)
      driver.stub(:wait_for_sshd).with('1.2.3.4', 'dhc-user', {}).and_return(true)

      return driver
    end

    it 'will not enable ssl_v3_only' do
      configured_driver.should_not_receive(:ssl_v3_only)
      configured_driver.create(state)
    end

    it 'will call create_server to create the instance' do
      configured_driver.should_receive(:create_server)
      configured_driver.create(state)
    end

    it 'will set the server_id in the current state' do
      configured_driver.create(state)
      expect(state[:server_id]).to eq('abcd1234')
    end

    it 'will set the hostname in the current state' do
      configured_driver.create(state)
      expect(state[:hostname]).to eq('1.2.3.4')
    end

    it 'will wait for sshd to be available' do
      configured_driver.should_receive(:wait_for_sshd).with('1.2.3.4', 'dhc-user', {}).and_return(true)
      configured_driver.create(state)
    end
  end
end

