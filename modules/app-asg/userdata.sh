#!/bin/bash

pip3.11 install ansible hvac &>>/opt/ansible.log
ansible-pull -i localhost, -U https://github.com/raghudevopsb78/expense-ansible get-secrets.yml -e env=${env} -e role_name=${component}  -e vault_token=${vault_token} &>>/opt/ansible.log
ansible-pull -i localhost, -U https://github.com/raghudevopsb78/expense-ansible expense.yml -e env=${env} -e role_name=${component} -e @~/secrets.json &>>/opt/ansible.log