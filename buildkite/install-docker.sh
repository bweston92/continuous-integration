#!/bin/bash
#
# Copyright 2017 The Bazel Authors. All rights reserved.
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

apt-get -qqy install apt-transport-https ca-certificates > /dev/null

# From https://download.docker.com/linux/ubuntu/gpg
curl -sSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt-get -qqy update > /dev/null
apt-get -qqy install docker-ce > /dev/null

# Docker group
usermod -aG docker buildkite-agent

# Disable the Docker service, as the startup script has to mount /var/lib/docker
# first.
if [[ -e /bin/systemctl ]]; then
  systemctl disable docker
else
  echo manual > /etc/init/docker.override
fi
