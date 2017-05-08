#!/usr/bin/env bash

tmpd="$(mktemp -d)"
pushd $tmpd

gpg -a --export alexander.pinnecke@googlemail.com > public-gpg.key
gpg -a --export-secret-keys alexander.pinnecke@googlemail.com  > secret-gpg.key
gpg --export-ownertrust > ownertrust-gpg.txt
zip -r ~/Dropbox/gpg.zip ./

popd
rm -rf $tmpd
