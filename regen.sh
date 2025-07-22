#!/bin/sh

set -e
envsubst -o gen-config.yaml -i config.yaml
flutter pub run ffigen --config gen-config.yaml
