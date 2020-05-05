#!/bin/sh

## xcode command line tools
xcode-select --install

## homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

## setup
brew update
brew upgrade
brew doctor || exit 1

## python & ansible & git
brew install python ansible

## ansible
sh $(cd $(dirname); pwd)/playbook.sh
