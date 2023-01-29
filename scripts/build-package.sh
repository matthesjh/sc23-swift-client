#!/bin/sh

if [ "${RUNNER_OS}" = "Linux" ]; then
  SWIFT_VERSION_NUMBER=5.7.3
  SWIFT_PLATFORM=ubuntu$(lsb_release -r -s)
  SWIFT_BRANCH=swift-${SWIFT_VERSION_NUMBER}-release
  SWIFT_VERSION=swift-${SWIFT_VERSION_NUMBER}-RELEASE

  echo "Downloading the Swift ${SWIFT_VERSION_NUMBER} toolchain..."
  wget https://download.swift.org/${SWIFT_BRANCH}/$(echo ${SWIFT_PLATFORM} | tr -d .)/${SWIFT_VERSION}/${SWIFT_VERSION}-${SWIFT_PLATFORM}.tar.gz
  tar xzf ${SWIFT_VERSION}-${SWIFT_PLATFORM}.tar.gz
  export PATH="${GITHUB_WORKSPACE}"/${SWIFT_VERSION}-${SWIFT_PLATFORM}/usr/bin:"${PATH}"
fi

echo "Using Swift version:"
swift -version

echo "Building package..."
swift build