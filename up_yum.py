# -*- coding: utf-8 -*-

import os
import subprocess

# 修改文件名
directory = '/usr/bin/'

for filename in os.listdir(directory):
    # if 'yum' in filename:
    if 'yum' == filename or "yum-config-manager" == filename:
        file_path = os.path.join(directory, filename)
        with open(file_path, 'r') as file:
            lines = file.readlines()
            if len(lines) > 0 and not lines[0].startswith('#!/usr/bin/python2.7'):
                lines[0] = lines[0].replace("python", "python2.7")
                with open(file_path, 'w') as modified_file:
                    modified_file.writelines(lines)
                print('已修改的文件：{}'.format(filename))

# 修改配置文件
def change_selinux_mode(mode):
    # 打开文件并读取内容
    with open('/etc/selinux/config', 'r') as file:
        lines = file.readlines()

    # 遍历每一行，找到并修改 SELINUX= 的行
    for i in range(len(lines)):
        if lines[i].strip().startswith('SELINUX=') and not lines[i].strip().startswith('#'):
            lines[i] = 'SELINUX={}\n'.format(mode)

    # 将修改后的内容写回文件
    with open('/etc/selinux/config', 'w') as file:
        file.writelines(lines)
    print('SELinux 模式已更改为 {}'.format(mode))

# 将 SELinux 模式设置为 permissive
change_selinux_mode("permissive")

# 修改指定文件的第一行
file_path = '/usr/libexec/urlgrabber-ext-down'

with open(file_path, 'r') as file:
    lines = file.readlines()

modified = False

if len(lines) > 0 and not lines[0].startswith('#! /usr/bin/python2.7'):
    lines[0] = lines[0].replace("python", "python2.7")
    with open(file_path, 'w') as modified_file:
        modified_file.writelines(lines)
    modified = True

if modified:
    print('已修改文件：{}'.format(file_path))
else:
    print('文件未被修改：{}'.format(file_path))
