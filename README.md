# Manual Bootstrap Instructions

## 1. Execute Bootstrap Script on fresh System
```bash
curl -fsSL https://raw.githubusercontent.com/robscodingplace/workstation-bootstrap/refs/heads/main/bootstrap.sh | bash
```

## 2. Take the printed public key and add it to your GitHub account
* [Direct Link](https://github.com/settings/ssh/new)
* GitHub → Settings → SSH and GPG keys → New SSH key

## 3. Clone the ansible-workstation Repository
```bash
git clone git@github.com:robscodingplace/ansible-workstation.git ~/ansible-workstation
```

## 4. Change into the ansible-workstation Directory
```bash
cd ~/ansible-workstation
```

# 4) Run ansible setup
```bash
make setup
```
You will be prompted for:

your sudo password

the Ansible Vault password

After completion, log out and log back in once
(to apply group membership changes such as Docker).