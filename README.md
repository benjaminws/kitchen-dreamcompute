# <a name="title"></a> Kitchen::Dreamcompute

[![Code
Climate](https://codeclimate.com/github/benjaminws/kitchen-dreamcompute.png)](https://codeclimate.com/github/benjaminws/kitchen-dreamcompute)

A Test Kitchen Driver for DreamCompute.

## <a name="installation"></a> Installation and Setup

Please read the [Driver usage][driver_usage] page for more details.

## <a name="config"></a> Configuration

Minimum config:

    driver:
      name: dreamcompute
      dreamcompute_username: <dreamcompute_username> || ENV['OS_AUTH_URL'}
      dreamcompute_api_key: <dreamcompute_api_key> || ENV['OS_PASSWORD']
      dreamcompute_auth_url: <dreamcompute_auth_url> || ENV['OS_AUTH_URL']
      require_chef_omnibus: latest
      image_name: <server image name>
      flavor_name: <server flavor name>
      username: <username for image>

Config options (and defaults):

    server_name: <unique_name> || randomly_generated_name
    groups: ['default']
    ssl_v3_only: false
    availability_zone: 'iad-1'
    ssh_key_id: ''
    flavor_id: '' || flavor_name
    image_id: '' || image_name

### <a name="config-require-chef-omnibus"></a> require\_chef\_omnibus

Determines whether or not a Chef [Omnibus package][chef_omnibus_dl] will be
installed. There are several different behaviors available:

* `true` - the latest release will be installed. Subsequent converges
  will skip re-installing if chef is present.
* `latest` - the latest release will be installed. Subsequent converges
  will always re-install even if chef is present.
* `<VERSION_STRING>` (ex: `10.24.0`) - the desired version string will
  be passed the the install.sh script. Subsequent converges will skip if
  the installed version and the desired version match.
* `false` or `nil` - no chef is installed.

The default value is unset, or `nil`.

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## <a name="authors"></a> Authors

Created and maintained by [Benjamin W. Smith][author] (<benjaminwarfield@just-another.net>)

## <a name="license"></a> License

Apache 2.0 (see [LICENSE][license])


[author]:           https://github.com/benjaminws
[issues]:           https://github.com/benjaminws/kitchen-dreamcompute/issues
[license]:          https://github.com/benjaminws/kitchen-dreamcompute/blob/master/LICENSE
[repo]:             https://github.com/benjaminws/kitchen-dreamcompute
[driver_usage]:     http://docs.kitchen-ci.org/drivers/usage
[chef_omnibus_dl]:  http://www.opscode.com/chef/install/
