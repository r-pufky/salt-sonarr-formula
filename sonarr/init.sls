{%- from "sonarr/map.jinja" import sonarr with context -%}

sonarr_ppa_repo:
  pkgrepo.managed:
    - name: deb http://apt.sonarr.tv/ master main
    - file: /etc/apt/sources.list.d/sonarr.list
    - keyid: A236C58F409091A18ACA53CBEBFF6B99D9B78493
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - sonarr_install

sonarr_install:
  pkg.installed:
    - pkgs:
      - {{ sonarr.package }}
{%- for pkg in sonarr.package_dependencies %}
      - {{ pkg }}
{%- endfor %}

sonarr_group:
  group.present:
    - name: {{ sonarr.group }}

sonarr_user:
  user.present:
    - name: {{ sonarr.user }}
    - groups:
      - {{ sonarr.group }}
    - home: {{ sonarr.data_dir }}
    - createhome: False
    - shell: /usr/sbin/nologin
    - system: True
    - require:
      - group: sonarr_group

sonarr_data_dir:
  file.directory:
    - name: {{ sonarr.data_dir }}
    - user: {{ sonarr.user }}
    - group: {{ sonarr.group }}
    - dir_mode: 0750
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: sonarr_user

sonarr_install_dir:
  file.directory:
    - name: {{ sonarr.install_dir }}

sonarr_systemd_file:
  file.managed:
    - name: /etc/systemd/system/{{ sonarr.package }}.service
    - source: salt://sonarr/files/sonarr.systemd.jinja
    - template: jinja

sonarr_service:
  service.running:
    - name: {{ sonarr.package }}
    - enable: True
    - require:
      - user: sonarr_user
      - file: sonarr_data_dir
      - file: sonarr_systemd_file

sonarr-restart:
  module.wait:
    - name: service.restart
    - m_name: {{ sonarr.package }}
    - require:
      - service: sonarr_service
    - watch:
      - file: sonarr_systemd_file
