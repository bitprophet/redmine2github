# Redmine => Github

This script is designed to copy Redmine tickets into a Github repository's Issues section, circa Github Issues v2 / Github API v3.

It was written for a very specific application: to port [Fabric](http://fabfile.org)'s hacked-up Redmine instance's data into Github Issues. Thus it makes a number of assumptions which may not hold true for others, which are documented in the NOTES file. It will still probably be very useful if properly tweaked.

It was originally tested/executed via a modified Redmine 0.8 install, running on Rails 2.1.2, via Rails' `script/runner` script.
