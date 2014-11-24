{% set gerrit = salt['pillar.get']('gerrit') %}
{% set user = salt['pillar.get']('gerrit:user', 'gerrit2') %}
{% set home = salt['pillar.get']('gerrit:home', '/home/' + user) %}
{% set repo = salt['pillar.get']('gerrit:repo', home + '/repo') %}

gerrit_user:
  user.present:
  - name: {{ user }}
  cmd.run:
  - name: ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''
  - user: {{ user }}
  - creates: {{ home }}/.ssh/id_rsa.pub

gerrit_war:
  file.managed:
  - name: {{ home }}/gerrit.war
  - user: {{ user }}
  - group: {{ user }}
{% if gerrit.source is defined %}
  - source: {{ gerrit.source }}
  - source_hash: {{ gerrit.source_hash }}
{% else %}
  - source: salt://gerrit/files/gerrit.war
{% endif %}

gerrit_init:
  cmd.run:
  - name: java -jar gerrit.war init --site-path {{ repo }} --batch --no-auto-start --install-plugin download-commands --install-plugin replication --install-plugin reviewnotes --install-plugin singleusergroup
  - user: {{ user }}
  - creates: {{ repo }}

gerrit_service_config:
  file.managed:
  - name: /etc/default/gerritcodereview
  - contents: GERRIT_SITE="{{ repo }}"

gerrit_service:
  file.symlink:
  - name: /etc/init.d/gerrit
  - target: {{ repo }}/bin/gerrit.sh
  service:
  - name: gerrit
  - sig: GerritCodeReview
  - running
  - enable: True
  - require:
    - file: gerrit_service
