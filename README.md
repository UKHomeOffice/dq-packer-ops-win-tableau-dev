# dq-packer-ops-win-tableau-dev

This AMI is used to create Tableau Deployment servers.
It is built on top of the Windows Bastion AMI with extra tools installed for Tableau.

## Features

### `packer.json`

This file contains a wrap up for Ansible script to be run inside a Windows Server 2019 

### `playbook.yml`

Ansible playbook installing the following:
- Tableau Desktop
- userdata script

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
