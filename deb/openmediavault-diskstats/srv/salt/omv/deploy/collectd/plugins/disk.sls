# This file is part of OpenMediaVault.
#
# @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
# @author    Volker Theile <volker.theile@openmediavault.org>
# @copyright Copyright (c) 2009-2018 Volker Theile
#
# OpenMediaVault is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# OpenMediaVault is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with OpenMediaVault. If not, see <http://www.gnu.org/licenses/>.

# Documentation/Howto:
# https://collectd.org/wiki/index.php/Plugin:Disk
# https://github.com/stedolan/jq/wiki/Cookbook

{% set disks = [] %}
# Get the configured mount points.
{% set mountpoints = salt['omv_conf.get_by_filter'](
  'conf.system.filesystem.mountpoint',
  {'operator': 'not', 'arg0': {'operator': 'stringContains', 'arg0': 'opts', 'arg1': 'bind'}}) %}
# Filter mounted file systems.
{% for mountpoint in mountpoints %}
  # Example:
  # {
  #     "dir": "/srv/dev-disk-by-id-scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-1-part1",
  #     "freq": 0,
  #     "fsname": "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-1-part1",
  #     "hidden": false,
  #     "opts": "defaults,nofail,user_xattr,noexec,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0,acl",
  #     "passno": 2,
  #     "type": "ext4",
  #     "uuid": "dd838a0f-d39c-4158-afc0-1622bf8cde78"
  # }
  # or
  # {
  #     "dir": "/srv/dev-disk-by-id-scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-1-part1",
  #     "freq": 0,
  #     "fsname": "008530ff-a134-4264-898d-9ce30eeab927",
  # }
  {% if salt['mount.is_mounted'](mountpoint.dir) %}
    {% set disk = salt['omv_utils.get_fs_parent_device_file'](mountpoint.fsname) %}
    # Extract the device name from '/dev/xxx'.
    {% set _ = disks.append(disk[5:]) %}
  {% endif %}
{% endfor %}
# Append the root filesystem.
{% set root_fs = salt['omv_utils.get_root_filesystem']() %}
{% set disk = salt['omv_utils.get_fs_parent_device_file'](root_fs) %}
{% set _ = disks.append(disk[5:]) %}

configure_collectd_conf_disk_plugin:
  file.managed:
    - name: "/etc/collectd/collectd.conf.d/disk.conf"
    - source:
      - salt://{{ slspath }}/files/collectd-disk.j2
    - template: jinja
    - context:
        disks: {{ disks | json }}
