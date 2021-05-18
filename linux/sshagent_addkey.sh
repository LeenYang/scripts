#!/bin/bash 

if [ ! -S ${HOME}/.ssh/ssh_auth_sock ]; then
  eval $(ssh-agent)
  ln -sf "${SSH_AUTH_SOCK}" ${HOME}/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=${HOME}/.ssh/ssh_auth_sock
ssh_keys=$(find  ~/.ssh -name id_rsa)
ssh_agent_keys=$(ssh-add -l | awk '{key=NF-1; print $key}')
echo $ssh_keys
echo $ssh_agent_keys

for k in "${ssh_keys}"; do
    for l in "${ssh_agent_keys}"; do
        if [[ ! "${k}" = "${l}" ]]; then
            ssh-add "${k}" > /dev/null 2>&1
        fi
    done
done
