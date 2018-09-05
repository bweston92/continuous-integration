# Copyright 2015 The Bazel Authors. All rights reserved.
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

# Android support

set -eu

# NDK
mkdir -p /home/ci/android
cd /home/ci/android
curl -o android-ndk.bin http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
chmod +x android-ndk.bin
./android-ndk.bin >/dev/null
rm android-ndk.bin

# Android SDK
mkdir -p /home/ci/android/android-sdk-linux
cd /home/ci/android/android-sdk-linux
curl -o tools.zip https://dl.google.com/android/repository/tools_r25.2.3-linux.zip
unzip tools.zip
rm tools.zip
expect -c '
set timeout -1;
spawn /home/ci/android/android-sdk-linux/tools/bin/sdkmanager --update
expect {
    "Accept? (y/N)" { exp_send "y\r" ; exp_continue }
    eof
}
'

# platform-tools is necessary for ADB. build-tools 26.0.1 is the oldest version
# that Bazel supports as of 0.5.4 and is necessary for aapt, dx, apksigner, etc.
# platforms 24, 25 and 26 are installed in case any future test is written that
# specifically relies on one of them. extras;android;m2repository is necessary
# for tests of our support library integration.
# This should be kept in sync with mac/mac-android.sh.
yes | tools/bin/sdkmanager \
  "platform-tools" \
  "build-tools;26.0.1" \
  "platforms;android-24" \
  "platforms;android-25" \
  "platforms;android-26" \
  "extras;android;m2repository"
chown -R ci /home/ci/android
