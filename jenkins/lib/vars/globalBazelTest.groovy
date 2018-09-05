// Copyright (C) 2017 The Bazel Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// A pipeline step that control a global test for Bazel:
//   - Bootstrap bazel and do some basic tests
//   - Deploy the artifacts (site, releases) and send mails
//   - Run all downstream job
def call(config = [:]) {
  def repository = config.get("repository", "https://bazel.googlesource.com/bazel")
  def branch = config.get("branch", "master")
  def extra_bazelrc = config.get("extra_bazelrc", "")
  def refspec = config.get("refspec", "+refs/heads/*:refs/remotes/origin/*")
  def json_config = config.configuration

  stage("Startup global test") {
    echo "Running global test for branch ${branch} (refspec: ${refspec})"
  }

  // First we bootstrap bazel on all platform
  stage("Bootstrap on all platforms") {
    bootstrapBazelAll(repository: repository,
                      branch: branch,
                      refspec: refspec,
                      configuration: json_config)
  }


  // Deployment steps
  def is_master = branch.matches('^(.*/)?master$')
  def is_rc = branch.matches('^(refs/heads/)?release-.*$')
  def is_release = branch.matches('^refs/tags/.*$')
  if(is_master || is_rc | is_release) {
    stage(is_master ? "Push website" : "Push release") {
      machine("deploy") {
        recursiveGit(repository: repository,
                     refspec: refspec,
                     branch: branch)
        if (!is_master) {
          def r_name = sh(script: "bash -c 'source scripts/release/common.sh; get_full_release_name'",
                          returnStdout: true).trim()
          if (!r_name.isEmpty()) {
            pushRelease(name: r_name,
                        configuration: json_config,
                        excludes: ["**/*.bazel.build.tar*", "**/bazel", "**/bazel.exe"])
            if (is_release) {
              stage("Install new release on all nodes") {
                build(job: "/maintenance/install-bazel", wait: false, propagate: false)
              }
            }
          }
        }
      }
    }
  }

  // Then we run all jobs in the Global folder except the global pipeline job (the current job).
  report = null
  stage("Test downstream jobs") {
    report = runAll(folder: "Global",
                    parameters: [
                      [$class: 'TextParameterValue',
                       name: 'EXTRA_BAZELRC',
                       value: "${extra_bazelrc}"],
                      [$class: 'StringParameterValue',
                       name: 'REPOSITORY',
                       value: "${repository}"],
                      [$class: 'StringParameterValue',
                       name: 'BRANCH',
                       value: "${branch}"],
                      [$class: 'StringParameterValue',
                       name: 'REFSPEC',
                       value: "${refspec}"]
                    ],
                    excludes: ["pipeline", currentBuild.getProjectName()])
  }

  stage("Publish report") {
    reportAB report: report, name: "Downstream projects"
  }
}
