#!/bin/sh -ex

mkdir -p /tmp/kind-manifests
sudo mount -r --bind $(pwd) /tmp/kind-manifests
