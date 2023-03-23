# dq-packer-ops-win-tableau-dev

This AMI is used to create a Tableau Development server and has got various tools installed required to manage Tableau and related services.

## Features

### `packer.json`

This file contains a wrap up for Ansible script to be run inside a Windows 2012 R2 server

### `playbook.yml`

Ansible playbook installing the following:
- PSTools
- Chocolatey package manager
- Python2.7
- Python3
- Google Chrome
- Putty
- AWS CLI
- AWS Toolkit for Powershell
- PGAdmin 1.18.1
- PGAdmin 4
- Microsoft SQL Management Studio
- Tableau Desktop
- DBeaver

### `connection_plugins` (Removed)
Hashicorp now recommends _directly_ connecting Packer (with the WinRM Communicator) from the Control Node (Drone) to the Target Node being configured (Packer Builder EC2 Instance) rather than via the Communicator proxy provided by the connection plugin. <br>
If the proxy is to be used the latest version of `packer.py` must be downloaded from https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/connection/ssh.py

#### `scripts`
- `disable-esc-and-iac.ps1` turn off annoying Windows pop-ups
- `monitor_stopped_win_services.ps1` checks if there are any service in the *stopped* state where they are set to *automatic* startup
- `setupwrm.ps1` enable WRM service so packer can interact with the instance
- `sysprep-bundleconfig.ps1` turn on sysprep using a custom xml config file
- `sysprep-ec2config.ps1` add EC2 specific sysprep values

## Deploying / Publishing
Drone min ver 0.5 is needed to deploy with `.drone.yaml` file

## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

More information in [`CONTRIBUTING`](./CONTRIBUTING)

## Licensing
The code in this project is licensed under this [`LICENSE`](./LICENSE)
