#!/bin/bash

find . -type d -exec chmod 777 {} \;
find . -type f -exec chmod 666 {} \;
find . -type f -name "*.sh" -exec chmod 777 {} \;

bundle exec jekyll serve
