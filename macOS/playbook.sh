#!/bin/sh

SCRIPTROOT=$(cd $(dirname $0); pwd)

ansible-playbook -i production ${SCRIPTROOT}/macosx.yml
