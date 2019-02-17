#!/bin/bash

cp build/app/outputs/apk/release/app-release.apk scripts/deploy/src/main/resources
cd scripts/deploy
./gradlew run