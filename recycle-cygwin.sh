#!/bin/bash

gem uninstall -x git-media
gem build git-media.gemspec
gem install git-media-*.gem
