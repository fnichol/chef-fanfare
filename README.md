# <a name="title"></a> chef-fanfare [![Build Status](https://secure.travis-ci.org/fnichol/chef-fanfare.png?branch=master)](http://travis-ci.org/fnichol/chef-fanfare)

## <a name="description"></a> Description

Data-driven application hosting.

## <a name="usage"></a> Usage

### <a name="usage-applications"></a> Server Recieving Deployed Applications

Include `recipe[fanfare::applications]` in your run\_list and add a data
bag item in the **fanfare_apps** data bag for each application you want
deployed into your infrastructure. See the [Data Bag](#databags) section for
more details.

### <a name="usage-datbases"></a> Server Hosting Application Databases

Include `recipe[fanfare::databases]` in your run\_list and and add a data
bag item in the **fanfare_apps** data bag for each application you want
deployed into your infrastructure. See the [Data Bag](#databags) section
for more details.

## <a name="requirements"></a> Requirements

### <a name="requirements-chef"></a> Chef

Tested on 0.10.8 but newer and older version should work just
fine. File an [issue][issues] if this isn't the case.

### <a name="requirements-platform"></a> Platform

The following platforms have been tested with this cookbook, meaning that
the recipes and LWRPs run on these platforms without error:

* ubuntu (10.04)

Please [report][issues] any additional platforms so they can be added.

### <a name="requirements-cookbooks"></a> Cookbooks

This cookbook depends on the following external cookbooks:

* [postgresql][postgresql_cb] (Opscode)
* [mysql][mysql_cb] (Opscode)
* [database][database_cb] (Opscode)
* [nginx][nginx_cb] (Opscode)
* [user][user_cb]
* [runit][runit_cb] (Opscode)

## <a name="installation"></a> Installation

Depending on the situation and use case there are several ways to install
this cookbook. All the methods listed below assume a tagged version release
is the target, but omit the tags to get the head of development. A valid
Chef repository structure like the [Opscode repo][chef_repo] is also assumed.

## <a name="installation-platform"></a> From the Opscode Community Platform

To install this cookbook from the Opscode platform, use the *knife* command:

    knife cookbook site install fanfare

### <a name="installation-librarian"></a> Using Librarian-Chef

[Librarian-Chef][librarian] is a bundler for your Chef cookbooks.
Include a reference to the cookbook in a [Cheffile][cheffile] and run
`librarian-chef install`. To install Librarian-Chef:

    gem install librarian
    cd chef-repo
    librarian-chef init

To use the Opscode platform version:

    echo "cookbook 'fanfare'" >> Cheffile
    librarian-chef install

Or to reference the Git version:

    cat >> Cheffile <<END_OF_CHEFFILE
    cookbook 'fanfare',
      :git => 'https://github.com/fnichol/chef-fanfare', :ref => 'v0.1.2'
    END_OF_CHEFFILE
    librarian-chef install

### <a name="installation-kgc"></a> Using knife-github-cookbooks

The [knife-github-cookbooks][kgc] gem is a plugin for *knife* that supports
installing cookbooks directly from a GitHub repository. To install with the
plugin:

    gem install knife-github-cookbooks
    cd chef-repo
    knife cookbook github install fnichol/chef-fanfare/v0.1.2

### <a name="installation-tarball"></a> As a Tarball

If the cookbook needs to downloaded temporarily just to be uploaded to a Chef
Server or Opscode Hosted Chef, then a tarball installation might fit the bill:

    cd chef-repo/cookbooks
    curl -Ls https://github.com/fnichol/chef-fanfare/tarball/v0.1.2 | tar xfz - && \
      mv fnichol-chef-fanfare-* fanfare

### <a name="installation-gitsubmodule"></a> As a Git Submodule

A dated practice (which is discouraged) is to add cookbooks as Git
submodules. This is accomplished like so:

    cd chef-repo
    git submodule add git://github.com/fnichol/chef-fanfare.git cookbooks/fanfare
    git submodule init && git submodule update

**Note:** the head of development will be linked here, not a tagged release.

## <a name="recipes"></a> Recipes

### <a name="recipes-default"></a> default

This recipe is a no-op and does nothing.

### <a name="recipes-applications"></a> applications

Processes a list of application deployment targets (collectively called
**ports**) with data drawn from a data bag. The default data bag is
`fanfare_apps`. This recipe includes *default*.

Use this recipe on your node if it is recieving deployed applications (i.e. it
is an application server).

### <a name="recipes-databases"></a> databases

Processes a list of databases to be managed with data drawn from a data bag.
The default data bag is `fanfare_apps`. This recipe includes *default*.

Use this recipe on your node if it hosting the database resources (i.e. it
is a database server).

## <a name="attributes"></a> Attributes

### <a name="attributes-root-path"></a> root_path

The base path into which all applications are deployed.

The default is `"/srv"`.

### <a name="attributes-default-db-type"></a> default_db_type

The database type to be used if not set in an application data bag item.

The default is `"postgresql"`.

### <a name="attributes-default-app-type"></a> default_app_type

The application type to be used if not set in an application data bag item.

The default is `"rails"`.

### <a name="attributes-first-http-port"></a> first_http_port

The starting HTTP port number for populating Foreman `.env` files.

The default is `8000`.

### <a name="attributes-default-env-path"></a> default_env_path

The intial `PATH` that will be used by all Foreman managed processes..

The default depends on the platform.

### <a name="attributes-http-ssl-certs-path"></a> http/ssl_certs_path

The base path where all public SSL certificate keys are located.

The default is `/etc/ssl/certs`.

### <a name="attributes-http-ssl-private-path"></a> http/ssl_private_path

The base path where all private SSL keys are located.

The default is `/etc/ssl/private`.

## <a name="lwrps"></a> Resources and Providers

There are **no** resources and providers in this cookbook.

## <a name="databags"></a> Data Bags

...coming soon...

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/Questions/Feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make.

## <a name="license"></a> License and Author

Author:: [Fletcher Nichol][fnichol] (<fnichol@nichol.ca>) [![endorse](http://api.coderwall.com/fnichol/endorsecount.png)](http://coderwall.com/fnichol)

Copyright 2012, Fletcher Nichol

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[chef_repo]:        https://github.com/opscode/chef-repo
[cheffile]:         https://github.com/applicationsonline/librarian/blob/master/lib/librarian/chef/templates/Cheffile
[database_cb]:      http://community.opscode.com/cookbooks/database
[kgc]:              https://github.com/websterclay/knife-github-cookbooks#readme
[librarian]:        https://github.com/applicationsonline/librarian#readme
[lwrp]:             http://wiki.opscode.com/display/chef/Lightweight+Resources+and+Providers+%28LWRP%29
[mysql_cb]:         http://community.opscode.com/cookbooks/mysql
[nginx_cb]:         http://community.opscode.com/cookbooks/nginx
[postgresql_cb]:    http://community.opscode.com/cookbooks/postgresql
[runit_cb]:         http://community.opscode.com/cookbooks/runit
[user_cb]:          http://community.opscode.com/cookbooks/user

[fnichol]:      https://github.com/fnichol
[repo]:         https://github.com/fnichol/chef-fanfare
[issues]:       https://github.com/fnichol/chef-fanfare/issues
