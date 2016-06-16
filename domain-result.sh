#!/bin/bash
rm -f /tmp/game_check
rm -f /tmp/nonegame_check
scp -i /etc/ansible/ida_rsa.key infra@122.128.109.26:/tmp/game_check /tmp/
scp -i /etc/ansible/ida_rsa.key infra@122.128.109.26:/tmp/nonegame_check /tmp/
