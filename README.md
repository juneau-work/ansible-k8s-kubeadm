### 环境变量: dev/group_vars/all ###
### 主机列表: dev/hosts ###
### 安装:  ###
```
export MASTER_CLUSTER_IP=192.168.130.100
bash tools/cert_gen.sh

action=install ; ansible-playbook -i dev/hosts $action.yml --extra-vars install_or_uninstall=$action
```
### 卸载: ###
```
action=uninstall ; ansible-playbook -i dev/hosts $action.yml --extra-vars install_or_uninstall=$action
```
