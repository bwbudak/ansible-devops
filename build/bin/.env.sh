#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$PATH:$DIR:$DIR/ptc

# Version file (semver)
export VERSION_FILE=${GITHUB_WORKSPACE}/.version
if [ -f "$VERSION_FILE" ]; then
  export VERSION=$(cat ${VERSION_FILE})
fi

# Previous version file (semver)
export PREVIOUS_VERSION_FILE=${GITHUB_WORKSPACE}/.previous_version
if [ -f "$PREVIOUS_VERSION_FILE" ]; then
  export PREVIOUS_VERSION=$(cat ${PREVIOUS_VERSION_FILE})
fi

# Setting the min release level will prevent builds taking place at a lower version change
# Keep in sync with initbuild.sh (which doesn't use this env file .. yet)
export SEMVER_MIN_RELEASE_LEVEL="${SEMVER_MIN_RELEASE_LEVEL:-build}"
export SEMVER_MAX_RELEASE_LEVEL="${SEMVER_MAX_RELEASE_LEVEL:-major}"

# During initbuild we record the release level (aka the version bump from the last release)
export SEMVER_RELEASE_LEVEL_FILE=${GITHUB_WORKSPACE}/.releaselevel
if [ -f "$SEMVER_RELEASE_LEVEL_FILE" ]; then
  export SEMVER_RELEASE_LEVEL=$(cat ${SEMVER_RELEASE_LEVEL_FILE})
fi

# Docker does not support "+" characters from semvar syntax so we replace "+" with "_"
# We should not actually deploy any "+build" releases anyway
export DOCKER_TAG=$(echo "$VERSION" | sed -e's/\+/_/g')
export DOCKER_PUSH_RETRIES=5

# Regular Expressions
export SEMVER_XYZ="(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
export SEMVER_PRE="(-(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)?"
export SEMVER_BUILD="(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?"
export SEMVER_REGEXP="^${SEMVER_XYZ}${SEMVER_PRE}${SEMVER_BUILD}$"

# Keep in sync with initbuild.sh (which doesn't use this env file .. yet)
export RELEASE_BRANCH_REGEXP="^(master|(0|[1-9][0-9]*)\.x|(0|[1-9][0-9]*).(0|[1-9][0-9]*)\.x)$"
export MAINTENANCE_BRANCH_REGEXP="^((0|[1-9][0-9]*)\.x|(0|[1-9][0-9]*).(0|[1-9][0-9]*)\.x)$"
export NO_RELEASE_BUILD_REGEXP="\+build"

# Semver control overrides for maintenance branches
# - On a maintenance branch minor and major commits are banned as it would take the branch out of scope
if [[ "${TRAVIS_BRANCH}" =~ $MAINTENANCE_BRANCH_REGEXP ]]; then
  export SEMVER_MAX_RELEASE_LEVEL=patch
fi


if [ -z $BUILD_SYSTEM_ENV_LOADED ]; then
  echo "BUILD_SYSTEM_ENV_LOADED is not defined yet"
  export BUILD_SYSTEM_ENV_LOADED=1

  if [ ! -z $GITHUB_ENV ]; then
    echo "GITHUB_ENV is defined, exporting properties to $GITHUB_ENV"
    # https://docs.github.com/en/actions/learn-github-actions/workflow-commands-for-github-actions#environment-files
    echo "VERSION=$VERSION" >> $GITHUB_ENV
    echo "VERSION_FILE=$VERSION_FILE" >> $GITHUB_ENV
    echo "VERSION=$VERSION" >> $GITHUB_ENV
    echo "DOCKER_TAG=$DOCKER_TAG" >> $GITHUB_ENV
    echo "DOCKER_PUSH_RETRIES=$DOCKER_PUSH_RETRIES" >> $GITHUB_ENV
    echo "SEMVER_MIN_RELEASE_LEVEL=$SEMVER_MIN_RELEASE_LEVEL" >> $GITHUB_ENV
    echo "SEMVER_MAX_RELEASE_LEVEL=$SEMVER_MAX_RELEASE_LEVEL" >> $GITHUB_ENV
    echo "SEMVER_RELEASE_LEVEL_FILE=$SEMVER_RELEASE_LEVEL_FILE" >> $GITHUB_ENV
    echo "SEMVER_RELEASE_LEVEL=$SEMVER_RELEASE_LEVEL" >> $GITHUB_ENV
    echo "RELEASE_BRANCH_REGEXP=$RELEASE_BRANCH_REGEXP" >> $GITHUB_ENV
    echo "NO_RELEASE_BUILD_REGEXP=$NO_RELEASE_BUILD_REGEXP" >> $GITHUB_ENV
    echo "BUILD_SYSTEM_ENV_LOADED=1" >> $GITHUB_ENV
  else
    echo "GITHUB_ENV is not defined"
  fi

  echo_h1 "Build Properties"
  echo_highlight "DIR ........................ $DIR"
  echo_highlight "PATH ....................... $PATH"
  echo_highlight ""
  echo_highlight "VERSION_FILE ............... $VERSION_FILE"
  echo_highlight "VERSION .................... $VERSION"
  echo_highlight "DOCKER_TAG ................. $DOCKER_TAG"
  echo_highlight "DOCKER_PUSH_RETRIES ........ $DOCKER_PUSH_RETRIES"
  echo_highlight ""
  echo_highlight "SEMVER_MIN_RELEASE_LEVEL ... $SEMVER_MIN_RELEASE_LEVEL"
  echo_highlight "SEMVER_MAX_RELEASE_LEVEL ... $SEMVER_MAX_RELEASE_LEVEL"
  echo_highlight "SEMVER_RELEASE_LEVEL_FILE .. $SEMVER_RELEASE_LEVEL_FILE"
  echo_highlight "SEMVER_RELEASE_LEVEL ....... $SEMVER_RELEASE_LEVEL"
  echo_highlight ""
  echo_highlight "RELEASE_BRANCH_REGEXP ...... $RELEASE_BRANCH_REGEXP"
  echo_highlight "NO_RELEASE_BUILD_REGEXP .... $NO_RELEASE_BUILD_REGEXP"
  echo_highlight ""
else
  echo "BUILD_SYSTEM_ENV_LOADED is already defined, skipping debug and export to GitHub env file"
fi


