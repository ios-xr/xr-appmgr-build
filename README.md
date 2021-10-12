# xr-appmgr-build
Scripts to build RPMs for use with the XR appmgr.

# Building an RPM

Create an `build.yaml` file and add entries for your app
```
- name: "alpine"
  release: "ThinXR_7.3.15" # Release should correspond to a file in release_configs dir
  version: "0.1.0" # Application semantic version 
  sources:
    - name: alpine # Will correspond to the source name on the router
      file: examples/alpine/swanagent.tar # Path from xr-appmgr-build root to image
  config-dir:
    - name: SwanAgent # The name of the directory for the app to mount in its docker run opts
      dir: examples/alpine/config
  copy_hostname: true # Copy router hostname into config dir (only useful for eXR platforms)
  copy_ems_cert: true # Copy router ems certificate into config dir
```
Build:
`./appmgr_build -b examples/alpine/build.yaml`

Once the RPM is built, scp it to the router, and install.

```
scp RPMS/x86_64/alpine-0.1.0-eXR_7.3.1.x86_64.rpm <router>:/harddisk:
```

Note that if you specify `copy_ems_cert` you must install the RPM after gRPC is configured (see above). The post-install script requires the ems certificate to have been created at install time or the application will be unable to access it.

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
