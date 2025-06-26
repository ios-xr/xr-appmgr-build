# xr-appmgr-build
Scripts to build RPMs for use with the XR appmgr.

# Building an RPM to be installed using appmgr cli workflow
(Scriplets support will be deprecated soon using this install method)

Create a `build.yaml` file and add entries for the app
```
packages:
- name: "alpine" # Will be the name of the rpm (Editable)
  release: "ThinXR_7.3.15" # Release is the release since when the support for this rpm has started and should correspond to a file in release_configs dir (Not editable)
  target-release: "ThinXR_7.3.15" # Target release if present, RPM name will have this target-release name, else will have above release name (Editable)
  version: "0.1.0" # Application semantic version (Editable)
  sources:
      name: alpine #This has to be same as tar.gz file name below
      file: examples/alpine/alpine.tar.gz # Path from xr-appmgr-build root to image (Editable)
            # Tar file  must be built with "--platform=linux/x86_64" option specified during docker build
  config-dir:
      name: alpine #This has to be same as config's parent directory name below
      dir: examples/alpine/config #Not editable
  data-dir:
      name: alpine #This has to be same as data's parent directory name below
      dir: examples/alpine/data #Not editable
  copy_hostname: true # Copy router hostname into config dir (only useful for eXR platforms)
  copy_ems_cert: true # Copy router ems certificate into config dir
```
Build:
`./appmgr_build -b examples/alpine/build.yaml`

Once the RPM is built, scp it to the router, and install.

```
scp RPMS/x86_64/alpine-0.1.0-eXR_7.3.1.x86_64.rpm <router>:/harddisk:
```

Note that if `copy_ems_cert` is specified, the RPM must be installed after gRPC is configured (see above). The post-install script requires the ems certificate to have been created at install time or the application will be unable to access it.
"grpc no-tls config should not be used if copy_ems_cert option is specified"


```
appmgr package install rpm /harddisk:/alpine-0.1.0-eXR_7.3.1.x86_64.rpm
```

Config:
```
appmgr application alpine activate type docker source alpine docker-run-opts "-v {app_install_root}/config/alpine-configs:/root/config"
```
To uninstall the RPM, use the following command:
```
appmgr package uninstall package alpine-0.1.0-eXR_7.3.1.x86_64
```


# Building an RPM to be installed using XR install cli workflow(LNT platform only)
(Scriplets are not supported using this install method)

Create a `build.yaml` file and add entries for the app
```
- name: "partner-alpine" # Prefix "owner-" or "partner-" for TPA apps (Prefix not editable)
  release: "7.10.1" # This is the release since when the support for this rpm has started and should correspond to a file in release_configs dir (Not editable)
  target-release: "7.10.1" # If present, this is the release for rpms to be installed, else above release is used. (Editable)
  version: "3.14" #Editable
  partner-name: "radware" # Needed only for Partner rpms (Editable)
  sources:
      name: alpine #This has to be same as tar.gz file name below
      file: examples/alpine/alpine.tar.gz # File must have "tar.gz" extension (Editable)
            # Tar file must be built with "--platform=linux/x86_64" option specified during docker build
  config-dir:
      name: alpine #This has to be same as config's parent directory name below
      dir: examples/alpine/config #Not editable
  data-dir:
      name: alpine #This has to be same as data's parent directory name below
      dir: examples/alpine/data #Not editable
  service-dir: #The service file is only applicable to the RPMs which needs containerz workflow support.
    - name: alpine #This has to be same as service's parent directory name below
      dir: examples/alpine/service #Do not change
```
The service dir above is only applicable to the RPMs which needs containerz workflow support.
Life cycle of third-party application having service file will be managed via containerz workflow only.
Users will not be able to perform app manager config post rpm installation on such applications.
To include service-dir file structure in the rpm being built, an option "--containerz" has to be passed
in the build command below explicitly.

Build:
`./appmgr_build -b examples/alpine/build.yaml`

Once the RPM is built, create a directory on the router at /harddisk:/owner-alpine/, scp it to this path, and install.

```
scp RPMS/x86_64/alpine-0.1.0-eXR_7.3.1.x86_64.rpm <router>:/harddisk:/owner-alpine/
```

Note that if `copy_ems_cert` is specified, the RPM must be installed after gRPC is configured (see above). The post-install script requires the ems certificate to have been created at install time or the application will be unable to access it.
"grpc no-tls config should not be used if copy_ems_cert option is specified"



```
 install source /harddisk:/owner-alpine/ all
```

Config:
```
appmgr application alpine activate type docker source alpine docker-run-opts "-v {app_install_root}/config/alpine-configs:/root/config"
```

The RPM can be uninstalled with the following:
```
install package remove owner-alpine
```

# Building a process-script RPM to be installed using appmgr cli workflow
Create a `build.yaml` file and add entries for the app
```
- name: "pscript" #This should not be changed (Not editable)
  release: "24.1.1" # This is the release since when the support for this rpm has started and should correspond to a file in release_configs dir (Not editable)
  target-release: "24.1.1" # If present, RPM name will have this target-release name, else will have above release name (Editable)
  version: "0.1.0" # Application semantic version (Editable)
  sources:
    - name: pscript # Update this with the rpm name to be built (Editable)
      dir: examples/pscript # All the files in this direcotory to be copied to process-script rpm (Editable)

```
Build:
`./appmgr_build -b examples/alpine/build.yaml`

Once the RPM is built, scp it to the router, and install.

```
scp RPMS/x86_64/pscript-0.1.0-24.1.1.x86_64.rpm <router>:/harddisk:
```
The RPM can be installed with the following:
(As it's not a docker container, no need to activate this rpm)
```
appmgr package install rpm /harddisk:/pscript-0.1.0-24.1.1.x86_64.rpm
```

Config:
The RPM can be uninstalled with the following:
```
appmgr package uninstall package pscript-0.1.0-24.1.1.x86_64.rpm
```
The files in the rpm, will be copied to below location in the device
```
/var/lib/docker/appmgr/ops-script-repo/exec/
```

RPM details can be obtained using below commands
```
rpm -qpl RPMS/x86_64/pscript-0.1.0-24.1.1.x86_64.rpm
warning: RPMS/x86_64/pscript-0.1.0-24.1.1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 73f45f20: NOKEY
/ops-script-repo/exec
/ops-script-repo/exec/pscript
/ops-script-repo/exec/pscript/.gitignore

rpm -qpi RPMS/x86_64/pscript-0.1.0-24.1.1.x86_64.rpm
warning: RPMS/x86_64/pscript-0.1.0-24.1.1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 73f45f20: NOKEY
Name        : pscript
Version     : 0.1.0
Release     : 24.1.1
Architecture: x86_64
Install Date: (not installed)
Group       : 3rd party application
Size        : 71
License     : Copyright (c) 2020 Cisco Systems Inc. All rights reserved
Signature   : DSA/SHA1, Thu 19 Oct 2023 03:59:30 PM IST, Key ID fd7228c573f45f20
Source RPM  : pscript-0.1.0-24.1.1.src.rpm
Build Date  : Thu 19 Oct 2023 03:59:30 PM IST
Build Host  : aa727e7f9b26
Relocations : /
Packager    : cisco
Summary     : pscript 0.1.0 compiled for IOS-XR 24.1.1
```
Optionally pass comma separated package name(s) in build command with -p option
```
./appmgr_build -b examples/alpine/build.yaml -p alpine,pscript

If -p option is not passed, the build will process all packages in build.yaml file.
```

# Building an owner-process-script RPM to be installed using XR cli workflow
Create a `build.yaml` file and add entries for the app
```
- name: "owner-pscript" #This should not be changed (Not editable)
  release: "24.1.1" # This is the release since when the support for this rpm has started and should correspond to a file in release_configs dir (Not editable)
  target-release: "24.1.1" # If present, RPM name will have this target-release name, else will have above release name (Editable)
  version: "0.1.0" # Application semantic version (Editable)
  sources:
    - name: pscript # Update this with the rpm name to be built (Editable)
      dir: examples/pscript # All the files in this direcotory to be copied to process-script rpm (Editable)

```
Build:
`./appmgr_build -b examples/alpine/build.yaml`

Once the RPM is built, scp it to the router, and install.

```
scp RPMS/x86_64/owner-pscript-0.1.0-24.1.1.x86_64.rpm <router>:/harddisk:/owner-pscript/
```
The RPM can be installed with the following:
(As it's not a docker container, no need to activate this rpm)
```
install source /harddisk:/owner-pscript/ all
```

The RPM can be uninstalled with the following:
```
install package remove owner-alpine
```
The files in the rpm, will be copied to below location in the device
```
/opt/owner/ops-script-repo/exec/
```

RPM details can be obtained using below commands
```
rpm -qpl RPMS/x86_64/owner-pscript-0.1.0-24.1.1.x86_64.rpm
warning: RPMS/x86_64/owner-pscript-0.1.0-24.1.1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 73f45f20: NOKEY
/opt/owner/ops-script-repo/exec
/opt/owner/ops-script-repo/exec/pscript
/opt/owner/ops-script-repo/exec/pscript/.gitignore

rpm -qpi RPMS/x86_64/owner-pscript-0.1.0-24.1.1.x86_64.rpm
warning: owner-pscript-0.1.0-24.1.1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID 530b8c02: NOKEY
Name        : owner-pscript
Version     : 0.1.0
Release     : 24.1.1
Architecture: x86_64
Install Date: (not installed)
Group       : 3rd party application
Size        : 71
License     : Copyright (c) 2020 Cisco Systems Inc. All rights reserved
Signature   : DSA/SHA1, Mon 22 Jan 2024 06:28:24 PM IST, Key ID dc8ed574530b8c02
Source RPM  : owner-pscript-0.1.0-24.1.1.src.rpm
Build Date  : Mon 22 Jan 2024 06:28:24 PM IST
Build Host  : 756440a098a2
Relocations : /
Packager    : cisco
Summary     : owner-pscript 0.1.0 compiled for IOS-XR 24.1.1
Description :
This packages the artifacts required to run a 3rd party app
```
# Building an Sandbox outer RPM to be installed using XR cli workflow
Create a `build.yaml` file and add entries for the app
```
- name: "owner-alpine" #Do not change the prefix "owner"
  release: "7.10.1" #Do not change
  target-release: "7.10.1" #Can be changed
  version: "3.14" #Can be changed
  sources:
    - name: sandbox
      dir: examples/sandbox_inner_rpms/rpms #Can be changed
```
Build:
`./appmgr_build -b examples/sandbox_inner_rpms/build.yaml --sandbox`

Once the RPM is built, scp it to the router, and install.

```
scp RPMS/x86_64/RPMS/x86_64/owner-alpine-3.14-7.10.1.x86_64.rpm <router>:/harddisk:/owner-alpine/
```
The RPM can be installed with the following:
(As it's not a docker container, no need to activate this rpm)
```
install source /harddisk:/owner-alpine/ all
```

The RPM can be uninstalled with the following:
```
install package remove owner-alpine
```
The files in the rpm, will be copied to below location in the device
```
/opt/owner/sandbox/
```

RPM details can be obtained using below commands
```
rpm -qpl RPMS/x86_64/owner-alpine-3.14-7.10.1.x86_64.rpm
warning: RPMS/x86_64/owner-alpine-3.14-7.10.1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID b98f0200: NOKEY
/opt/owner/sandbox
/opt/owner/sandbox/owner-alpine-3.14-7.11.1.x86_64.rpm


rpm -qpi RPMS/x86_64/owner-alpine-3.14-7.10.1.x86_64.rpm
warning: RPMS/x86_64/owner-alpine-3.14-7.10.1.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID b98f0200: NOKEY
Name        : owner-alpine
Version     : 3.14
Release     : 7.10.1
Architecture: x86_64
Install Date: (not installed)
Group       : 3rd party application
Size        : 6485188
License     : Copyright (c) 2024 Cisco Systems Inc. All rights reserved
Signature   : DSA/SHA1, Wed 14 May 2025 04:57:29 PM IST, Key ID a0fef849b98f0200
Source RPM  : owner-alpine-3.14-7.10.1.src.rpm
Build Date  : Wed 14 May 2025 04:57:29 PM IST
Build Host  : 41c1b44adfd0
Relocations : / 
Packager    : cisco
Summary     : owner-alpine 3.14 compiled for IOS-XR 7.10.1
Description :
RPM built for use with IOS-XR appmgr.

XR-appmgr-build version: 46055cab7d8ceff6fd1c3444195761574ac2e146

# Build and Setup instructions

## Setting up the build environment
The RPM build takes place inside a docker container. The image for the container is defined in the corresponding release config file. The corresponding docker image is built as a part of each RPM build.

### Dependencies for MacOSX

#### Install greadlink through coreutils

```
brew install coreutils
```

#### Symlink to greadlink to make readlink available

```
macosx:xr-app-manager akshshar$ sudo ln -s /usr/local/bin/greadlink /usr/local/bin/readlink
macosx:xr-app-manager akshshar$ ls -l /usr/local/bin/readlink
lrwxr-xr-x  1 root  admin  24 Oct 18 15:58 /usr/local/bin/readlink -> /usr/local/bin/greadlink
macosx:xr-app-manager akshshar$
```

### Dependencies for Macosx and linux
Install docker on the build machine.
Follow instructions here for the relevant platform:

><https://docs.docker.com/v17.09/engine/installation/>
