Домашнее задание
Реализация GFS2 хранилища на виртуалках под виртуалбокс

Для того чтобы развернуть стенд, нужно выполнить следующую команду:
terraform init && terraform apply -auto-approve && \
sleep 30 && ansible-playbook ./provision.yml
