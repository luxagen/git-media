#!/bin/bash

sudo gem uninstall -x git-media
gem build git-media.gemspec
gem install --user-install git-media-*.gem
