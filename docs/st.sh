#!/usr/bin/bash

function setup()
{
module load python/3.7
source ~/COVID-19/py37/bin/activate
}

# setup
mkdocs build
mkdocs gh-deploy

git add .gitignore
git commit -m ".gitignore"
git add README.md
git commit -m "README"
git add docs
git commit -m "gwas2 utitlities"
git add mkdocs.yml
git commit -m "mkdocs.yml"
git push
