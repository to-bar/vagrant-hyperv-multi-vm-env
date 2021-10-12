# Vagrant Hyper-V multi-machine environment

Config file driven Hyper-V multi-machine environment with NAT network and static IP addresses

## Requirements

- Windows with Hyper-V [enabled](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)
- [Vagrant](https://www.vagrantup.com/downloads.html) (tested with v2.2.18)

## Install

```shell
git clone --depth=1 https://github.com/to-bar/vagrant-hyperv-multi-vm-env.git
```

## Usage

1. Open command prompt as administrator
2. Go to project's directory

    ```shell
    cd vagrant-hyperv-multi-vm-env
    ```

3. Edit `config.yml` file
4. Run Vagrant

    - Create environment

        ```shell
        vagrant up
        ```

    - Stop environment

        ```shell
        vagrant halt
        ```

    - Destroy environment (append `-f` to destroy without confirmation)

        ```shell
        vagrant destroy
        ```

    - Create snapshot of entire environment

        ```shell
        vagrant snapshot save <snapshot-name>
        ```

    - Create snapshot of single machine

        ```shell
        vagrant snapshot save <vm-name> <snapshot-name>
        ```

    - Restore environment from snapshot

        ```shell
        vagrant snapshot restore <snapshot-name>
        ```

    - List snapshots

        ```shell
        vagrant snapshot list
        ```

    - Remove snapshot

        ```shell
        vagrant snapshot delete <snapshot-name>
        ```

5. Connect to VM

    - Using SSH client

        ```shell
        ssh vagrant@<vm-ip>
        ```

    - Using Vagrant

        ```shell
        vagrant ssh [options] [name|id] [-- extra ssh args]
        ```

## Supported boxes

This project was tested with the following boxes:

- centos/7
- generic/rhel7
- generic/ubuntu1804
