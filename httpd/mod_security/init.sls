{% import_yaml "httpd/mod_security/default.yaml" as modsec %}

{% set modsecurity = salt['grains.filter_by'](
    modsec
, grain='os_family', merge=salt['pillar.get']('httpd:mod_security')) or {} %}


include:
  - httpd

mod-security:
  pkg.installed:
    - name: {{ modsec.package }}
    - order: 180
    - require:
      - pkg: apache

{% if modsec.crs_install %}
mod-security-crs:
  pkg.installed:
    - name: {{ modsec.crs_package }}
    - order: 180
    - require:
      - pkg: mod-security
{% endif %}

{% if modsec.manage_config %}
mod-security-main-config:
  file.managed:
    - name: {{ modsec.config_file }}
    - order: 220
    - template: jinja
    - source:
      - {{ 'salt://apache/files/' ~ salt['grains.get']('os_family') ~ '/modsecurity.conf.jinja' }}
    - context: {{ modsec }}
    - require:
      - pkg: mod-security
    - watch_in:
      - module: apache-reload
{% endif %}

{% if grains['os_family']=="Debian" %}
a2enmod security2:
  cmd.run:
    - unless: ls /etc/apache2/mods-enabled/security2.load && ls /etc/apache2/mods-enabled/security2.conf
    - order: 225
    - require:
      - pkg: mod-security
    - watch_in:
      - module: apache-restart
{% endif %}
