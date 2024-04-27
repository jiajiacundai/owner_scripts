# -*- coding: utf-8 -*-

import os
import subprocess

# 修改文件名
directory = '/usr/bin/'

for filename in os.listdir(directory):
    # if 'yum' in filename:
    if 'yum' == filename or "yum-config-manager" == filename:
        file_path = os.path.join(directory, filename)
        with open(file_path, 'r', encoding="us-ascii") as file:
            lines = file.readlines()
            if len(lines) > 0 and not lines[0].startswith('#!/usr/bin/python2.7'):
                lines[0] = lines[0].replace("python", "python2.7")
                with open(file_path, 'w', encoding="us-ascii") as modified_file:
                    modified_file.writelines(lines)
                print('已修改的文件：{}'.format(filename))

# 修改配置文件
def change_selinux_mode(mode):
    config_file_path = "/etc/selinux/config"
    sed_command = f"sed -i 's/^SELINUX=.*/SELINUX={mode}/' {config_file_path}"
    subprocess.run(sed_command, shell=True, check=True)
    print(f"SELinux mode has been changed to {mode}")

# 将SELinux模式设置为permissive
change_selinux_mode("permissive")

# 修改指定文件的第一行
file_path = '/usr/libexec/urlgrabber-ext-down'

with open(file_path, 'r', encoding="us-ascii") as file:
    lines = file.readlines()

modified = False

if len(lines) > 0 and not lines[0].startswith('#! /usr/bin/python2.7'):
    lines[0] = lines[0].replace("python", "python2.7")
    with open(file_path, 'w', encoding="us-ascii") as modified_file:
        modified_file.writelines(lines)
    modified = True

if modified:
    print('已修改文件：{}'.format(file_path))
else:
    print('文件未被修改：{}'.format(file_path))
