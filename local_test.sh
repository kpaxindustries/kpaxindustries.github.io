#!/bin/bash

#Copy assets from Windows
rsync -av /c/Users/mail/Documents/my-awsome-site/assets/* assets/

sudo find . -type d -exec chmod 777 {} \;
sudo find . -type f -exec chmod 666 {} \;
sudo find . -type f -name "*.sh" -exec chmod 777 {} \;

bundle exec jekyll serve
