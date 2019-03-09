#!/bin/sh

## xcode command line tools
xcode-select --install

## homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

## setup
brew upgrade
brew update
brew doctor || exit 1

## python & ansible & git
brew install python ansible

## ansible
sh $(cd $(dirname); pwd)/playbook.sh
