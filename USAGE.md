# Usage instructions and examples

## Common settings

1. Clone this repository
2. Edit *group_vars/meet/main.yml*
- Set *meet_domain* to the DNS name for your Jitsi Meet instance. This must
be resolvable in order to obtain a Let's Encrypt certificate.
- Set *le_email* to your email address, used **only** to obtain the LE certificate
- Change *xmpp_auth* to "ldap" or "token" if you want to limit access to your
Jitsi Meet. Even then you may allow unauthenticated users, after an
authenticated one created a room, by setting *allow_guests* to "true".
- Optionally configure "token" or "ldap" settings.

3. (optional) By default, SSH with the *root* user will be used to access the
   servers involved. If you'd rather use a different user with *sudo*, edit
   *site.yml* and change the occurrences of `user: root` with:

        become: yes
        become_user: root
        become_method: sudo

## Single node deployment

4. Edit the *hosts* file and add your server name to the `[central]` and
   `[videobridges]` groups. If you also want to run *jibri* on it, add its name
   to the `[jibris]` group.
5. Copy, or rename, *host_vars/central_host* to *host_vars/your_server_name*.
6. Edit *main.yml* in that directory and set *videobridge_user* and
   *videobridge_muc_nick*, since a videobridge would run in the host. You may
   use your hostname for both.
7. If you want to run a broadcaster "jibri" on your host, also set *jibri_user*
   and *jibri_muc_nick*.
8. (optional) If you want to get prometheus stats from your videobridge, set
   *run_exporter_container* to "true". The exporter will expose port 9102.
9. Edit "0secret.yml" and set password for the XMPP users the different
   components will use. If you plan to keep your configuration in a git repository,
   encrypt this file with **ansible-vault** before committing your passwords in
   git.
10. Run the playbook, and enjoy (if everything worked as expected):

        ansible-playbook -i hosts site.yml

## Multiple node deployment (several videobridges and/or jibri instances)

4. Edit the *hosts* file and add your main server name to the `[central]`
   group.  This server will run "jicofo" and "prosody" (authenticating users
   and Jitsi components like videobridges and jibris). It will also run the
   webserver where the *meet_domain* points to. If you also want to run a
   videobridge or jibri in it, add it to the `[videobridges]` or `[jibris]`
   groups.
5. Add all the servers that will run a videobridge or jibri to the
   corresponding groups in the *hosts* file.
6. Copy *host_vars/videobridge_only_host* as *host_vars/videobridge_server_name*
   for all the servers running as videobridge, and do the same with
   *host_vars/jibri_only_host* for those running jibri. You can concatenate the
   variables in both template directories to setup a host with both a
   videobridge and a jibri service.
7. Edit the *main.yml* and *0secret.yml* files for all the hosts and encrypt
   the latter with **ansible-vault** if you plan to keep them in a repository.
8. Run the playbook, and enjoy (if everything worked as expected):

       ansible-playbook -i hosts site.yml

## Adding new servers to your setup

If, at a later time, you want to add more videobridge or jibri servers, just
add their configuration to *hosts_vars* and run the playbook with the "jibri"
or "videobridge" tags. Also, if they will be using their own XMPP user/password,
run the playbook with the "xmppusers" tag so that the credentials get created
in prosody.

To add a new videobridge:

    ansible-playbook -i hosts site.yml --tags xmppusers
    ansible-playbook -i hosts site.yml --tags videobridge

To add a new jibri server:

    ansible-playbook -i hosts site.yml --tags xmppusers
    ansible-playbook -i hosts site.yml --tags jibri

## Jibri recording (and upload to a storage of your choice)

If you want to store your meetings' recordings, edit *group_vars/meet/main.yml*
to enable recording and point *recording_processing_script* to a script that
will receive, as a single argument, the path to the directory containing a
".mp4" file and a metadata.json file. You may use rclone
[rclone](https://rclone.org/) in the script to upload the files to Google
Drive, Dropbox or any other backend supported.
