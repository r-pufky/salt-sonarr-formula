{%- from "sonarr/map.jinja" import sonarr with context -%}

sonarr-dependencies:
  pkg.installed:
    - pkgs:
{%- for pkg in sonarr.pkg_dependencies %}
      - {{ pkg }}
{%- endfor %}

sonarr-user:
  user.present:
    - name: {{ sonarr.user }}
    - home: {{ sonarr.data_dir }}
    - createhome: False
    - shell: /usr/sbin/nologin
    - system: True

sonarr-install-dir:
  file.directory:
    - name: {{ sonarr.install_dir }}

sonarr-binary-package:
  archive.extracted:
    - name: {{ sonarr.install_dir }}
    - source: {{ sonarr.binary_archive }}
{%- if sonarr.get('binary_hash') %}
    - source_hash: {{ sonarr.binary_hash }}
{%- else %}
    - skip_verify: True
{%- endif %}
    - archive_format: tar
    - if_missing: {{ sonarr.install_dir }}/NzbDrone.exe
{%- if salt['grains.get']('salversioninfo') < [2016, 11, 0] %}
    - tar_options: '--strip-components=1'
{%- else %}
    - options: '--strip-components=1'
    - enforce_toplevel: False
{%- endif %}
    - require:
      - file: sonarr-install-dir

sonarr-data-dir:
  file.directory:
    - name: {{ sonarr.data_dir }}
    - user: {{ sonarr.user }}
    - group: {{ sonarr.user }}
    - require:
      - user: {{ sonarr.user }}

sonarr-systemd-file:
  file.managed:
    - name: /etc/systemd/system/sonarr.service
    - source: salt://sonarr/files/sonarr.service.jinja
    - template: jinja

sonarr-service:
  service.running:
    - name: sonarr
    - enable: True
    - require:
      - user: sonarr-user
      - archive: sonarr-binary-package
      - file: sonarr-data-dir
      - file: sonarr-systemd-file

sonarr-restart:
  module.wait:
    - name: service.restart
    - m_name: sonarr
    - require:
      - service: sonarr-service
    - watch:
      - service: sonarr-service
