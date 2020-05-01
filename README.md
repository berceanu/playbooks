# playbooks
Collection of ansible playbooks

To run, do 

```
$ ansible-playbook playbook.yml --ask-become-pass -v
```

or, in order to run the playbook locally,

```
$ ansible-playbook --connection=local --inventory 127.0.0.1, playbook.yml
```

