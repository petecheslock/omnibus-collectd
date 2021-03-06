#
# Copyright:: Pete Cheslock <petecheslock@gmail.com>
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "libkvm"
description "On UNIX systems where we bootstrap a compiler, copy the libkvm lib"

if platform == "freebsd"
  build do
    if File.exists?("/lib/libkvm.so.5")
      command "cp -f /lib/libkvm.so.5 #{install_dir}/embedded/lib/"
    else
      raise "cannot find libkvm.so.5"
    end
  end
end

