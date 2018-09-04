#!/bin/bash

jekyll build
rsync -av _site/* u75441087@home503732484.1and1-data.host:/kunden/homepages/20/d503732484/htdocs/secure/writeups/

