#!/bin/bash


ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible get-secrets.yml -e env=${env} -e role=${component}  -e vault_token=${vault_token} &>>/opt/ansible.log
ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible ansible.yml -e env=${env} -e role=${component} -e @~/secrets.json -e-e only_deployment=false &>>/opt/ansible.log