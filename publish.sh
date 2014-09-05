#!/bin/bash

## Script modified by JAM at Norwich on 5/9/2014

## Copy site to github repository 
git add -A
git commit -m "update site $(date +"%x %r")"
git pull rtut master
git push rtut master
echo "Site updated $(date +"%x %r") on Github server"

## Send site to Amazon S3 for web hosting
s3cmd sync --delete-removed _site/ s3://jamaas.com
echo "Site updated $(date +"%x %r") on Amazon S3"

