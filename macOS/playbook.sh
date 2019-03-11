#!/bin/sh

cd $(dirname $0)

ansible-playbook -i production macosx.yml
