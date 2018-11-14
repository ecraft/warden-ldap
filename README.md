# Warden::Ldap

[![Build Status](https://travis-ci.org/ecraft/warden-ldap.svg)](https://travis-ci.org/ecraft/warden-ldap)

**NOTE**: This is a fork of warden-ldap by renewablefunding. There's no current gem published anywhere.

Adds LDAP Strategy for [warden](https://github.com/wardencommunity/warden) using the [net-ldap](https://github.com/ruby-ldap/ruby-net-ldap) library.

## Installation (Bundler & Git only)

Add this line to your application's Gemfile:

```ruby
gem 'warden-ldap', git: 'https://github.com/ecraft/warden-ldap.git'
```

And then execute:

    $ bundle

## Usage

1. Install gem per instructions above
2. Initialize the `Warden::Ldap` adapter:

```ruby
Warden::Ldap.configure do |c|
  c.config_file = '/absolute/path/to/config/ldap_config.yml'
  c.env = 'test'
end
```

3. Add the `ldap_config.yml` to configure connection to ldap server. See `spec/fixtures/ldap_config_sample.yml`.

## Configuration

Configuration is done in YAML.

The content is preprocessed using ERB before being parsed as YAML.

```yml

## Authorizations
#
# This is a YAML alias, referred to in the environments below

authorizations: &AUTHORIZATIONS
  url: ldap://your.ldap.example.com/dc=ds,dc=renewfund,dc=com
  username: <%= ENV['LDAP_USERNAME'] %>
  password: <%= ENV['LDAP_PASSWORD'] %>
  users:
    base:
      - ou=users
    scope: subtree
    filter: "(&(objectClass=user)(emailAddress=$username))"
    attributes:
      username: "userId"
      email: "emailAddress"
  groups:
    base:
      - ou=groups
    scope: subtree
    filter: "(&(objectClass=group)(member=$dn))"
    attributes:
      name: "cn"
    nested: true

test: 
  <<: *AUTHORIZATIONS
  url: ldap://localhost:1389/dc=example,dc=org

development: 
  <<: *AUTHORIZATIONS

production: 
  <<: *AUTHORIZATIONS
  ssl: start_tls
```

### `url`

An `ldap://` URL to the LDAP server. Add any base (aka "treebase") as
the path of this URL.

### `username`

The username of the account of the LDAP server which can search for users.

### `password`

The password of the account of the LDAP server which can search for users.

### `users/base`

The LDAP treebase part of the query to find users.

### `users/scope`

LDAP search scope for the query to find users.

| Configuration value | Scope used |
| ---    | ---         |
| `base` or `base_object` |  `Net::LDAP::SearchScope_BaseObject` |
| `level` or `single_level` |  `Net::LDAP::SearchScope_SingleLevel` |
| `subtree` or `whole_subtree` |  `Net::LDAP::SearchScope_WholeSubtree` (default) |

### `users/filter`

The "search for user" query is configured using the LDAP query format.
The string `$username` is interpolated into the query as the username of
the user you're trying to authenticate as.

### `users/attributes`

A Hash where the keys are the User object properties and the
values are attributes on the User's LDAP entry.

### `groups/base`

The LDAP treebase part of the query to find which groups a user belongs to.

### `groups/scope`

LDAP search scope for the query to find groups. See `users/scope` for
possible configuration values.

### `groups/filter`

The "search for groups" query is configured using the LDAP query format.
The string `$dn` is interpolated into the query as the distinguished name of
the group you're constraining the authentication to.

### `groups/attributes`

A Hash where the keys are the Group object properties and the
values are attributes on the Group's LDAP entry.

### `groups/nested`

Boolean. Default: `false`.

If true, the search for groups will continue into each group.

## Testing

Enable mocked authentication using the optional configuration `test_environments`.

`test_environments` accepts an array of environments to mock, where authentication works as long as username and password are supplied, and password is not "fail".

```ruby
Warden::Ldap.configure do |c|
  # Enable mocked authentication in the "test" and "golden" environments
  c.test_environments = %w(test golden)
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
