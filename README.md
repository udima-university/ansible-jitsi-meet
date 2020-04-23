# Jitsi Meet Ansible Playbook

This playbook will install the Jitsi Meet stack in one or more servers.  It is
developed and tested on Debian 10 Buster. It may work on other Debian releases
or Ubuntu, but it has not been tested there.

## How do I use it?

Simple clone it and rename the host configuration directories in *hosts_vars/*
to match your hosts.
Also edit *group_vars/meet* and the *hosts* file to suit your needs.
Further instructions in [USAGE.md](USAGE.md).
If you're using a git repository to hold your configuration, don't forget to
use **ansible-vault** to encrypt sensitive information. That's why the passwords
are stored on *0secret.yml* files.

You may run everything on one host. Or have separate hosts for videobridges and
jibris. If you want to run a videobridge and/or a jibri instance on the central
server, just include it in the "[videobridges]" and/or "[jibris]" group.

The *meet_domain* variable in *group_vars/meet* should have a DNS entry and
point to your "central" server since a Let's Encrypt certificate will be
generated during the installation.

Once you've gone through the hosts/variables you may run the playbook with:

    ansible-playbook -i hosts site.yml

If your hosts are behind NAT or a firewall, remember to check the ports
required to run Jitsi Meet (80,443 TCP and 1000 UDP at least).

## User authentication support

This playbook supports three kinds of user authentication, all managed in
*group_vars/meet/main.yml*:
- None, everyone can join or start a room
- Token based, so your application can issue tokens that control user access
  and permissions (moderators). For example using [Moodle's token module](https://github.com/udima-university/moodle-mod_jitsi)
- LDAP based. Well... that.

Both token and LDAP authentication can also allow non-authenticated users in
(depending on the *allow_guests* value).

You may switch from one authentication scheme to another by editing the file
previously mentioned and running:

    ansible-playbook -i hosts site.yml --tags authconf

## What are the system requirements for running ~~Jitsi Meet~~ a jibri instance?

Jibri depends on the [ALSA loopback module](https://github.com/jitsi/jibri/blob/master/README.md#alsa-and-loopback-device).
If your server is running on a cloud platform, or with a kernel other than
Debian's default, make sure you have support for the "snd-aloop" module
**before** running the playbook on it.

For example, on Google Cloud instances, you need to run:

    apt install linux-image-amd64
    apt purge linux-image-*cloud*
    reboot

After that, you may run the playbook.

## Final notes

The playbook has some hacks, like using Debian's certbot package instead of
downloading it from Jitsi's packages postint or installing openjdk-8 from
Stretch, to better deal with some packaging behaviour/configuration in
ansible. The Jitsi project is **very** active nowadays and this playbook will
be (hopefully) frequently revisited to adapt to its changes. Please report any
issues or send your PRs.

