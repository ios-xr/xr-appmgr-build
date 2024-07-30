# xr-appmgr-build
Scripts to build RPMs for use with the XR appmgr.

# Building an RPM

Create a `build.yaml` file and add entries for your app
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

# Building a TPA  RPM
Create a `build.yaml` file and add entries for your app
```
- name: "partner-alpine" # Prefix "owner-" or "partner-" for TPA apps (Prefix not editable)
  release: "7.10.1" # This is the release since when the support for this rpm has started and should correspond to a file in release_configs dir (Not editable)
  target-release: "7.10.1" # If present, this is the release for rpms to be installed, else above release is used. (Editable)
  version: "3.14" #Editable
  partner-name: "radware" # Needed only for Partner rpms (Editable)
  sources:
      file: examples/alpine/alpine.tar.gz # File must have "tar.gz" extension (Editable)
            # Tar file must be built with "--platform=linux/x86_64" option specified during docker build
  config-dir:
      dir: examples/alpine/config #Not editable
  data-dir:
      dir: examples/alpine/data #Not editable
```
Build:
`./appmgr_build -b examples/alpine/build.yaml`

Once the RPM is built, scp it to the router, and install.

```
scp RPMS/x86_64/alpine-0.1.0-eXR_7.3.1.x86_64.rpm <router>:/harddisk:
```

Note that if you specify `copy_ems_cert` you must install the RPM after gRPC is configured (see above). The post-install script requires the ems certificate to have been created at install time or the application will be unable to access it.
"grpc no-tls config should not be used if copy_ems_cert option is specified"


```
appmgr package install rpm /harddisk:/alpine-0.1.0-eXR_7.3.1.x86_64.rpm
```

Config:
```
appmgr application alpine activate type docker source alpine docker-run-opts "-v {app_install_root}/config/alpine-configs:/root/config"
```

You can uninstall the RPM with the following:
```
appmgr package uninstall package alpine-0.1.0-eXR_7.3.1.x86_64
```

# Building a process-script RPM
Create a `build.yaml` file and add entries for your app
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
You can install the RPM with the following:
(As it's not a docker container, no need to activate this rpm)
```
appmgr package install rpm /harddisk:/pscript-0.1.0-24.1.1.x86_64.rpm
```

Config:
You can uninstall the RPM with the following:
```
appmgr package uninstall package pscript-0.1.0-24.1.1.x86_64.rpm
```
The files in the rpm, will be copied to below location in the device
```
/var/lib/docker/appmgr/ops-script-repo/exec/
```

You can get rpm details using below commands
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
We can optionally pass comma separated package name(s) in build command with -p option
```
./appmgr_build -b examples/alpine/build.yaml -p alpine,pscript

If we don't pass -p option, it will build for all the packages in build.yaml file.
```

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
