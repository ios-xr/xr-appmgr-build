# owner-rpm-build.sh

A wrapper script that packages a Docker image (`.tar.gz`) into an RPM for deployment on IOS-XR via appmgr. It generates an RPM spec file, builds the RPM using `build_rpm.sh`, and places the final artifact in the specified output directory.

## Output

The resulting RPM follows the naming convention:

```
owner-<name>-<version>-<release>.<arch>.rpm
```

When installed on IOS-XR, the Docker image is placed under:

```
/opt/owner/<name>/
```

## Usage

```bash
./owner-rpm-build.sh -n <name> -v <version> -r <release> -s <source> -o <outputdir> [-a <arch>]
```

### Required Options

| Option | Description |
|---|---|
| `-n, --name` | Application name (will be prefixed with `owner-` in the RPM) |
| `-v, --version` | Version string (e.g. `1.0.0`) |
| `-r, --release` | Release string (e.g. `r1`) |
| `-s, --source` | Path to the Docker image `.tar.gz` file |
| `-o, --outputdir` | Directory where the final RPM will be placed |

### Optional Options

| Option | Description |
|---|---|
| `-a, --arch` | Target architecture (default: `x86_64`) |
| `-h, --help` | Show help message |

## Validation

The script performs the following checks before building:

- All required options must be provided.
- The source file must exist and have a `.tar.gz` extension.
- The source filename (without extension) must match the `--name` value. For example, `--name fibagent` requires the source file to be named `fibagent.tar.gz`.

## Example

```bash
./owner-rpm-build.sh \
    -n fibagent \
    -v 1.0.0 \
    -r r1 \
    -s /path/to/fibagent.tar.gz \
    -o ./output
```

This produces `owner-fibagent-1.0.0-r1.x86_64.rpm` in the `./output/` directory.

## How It Works

1. Validates all inputs and checks source file naming consistency.
2. Creates a temporary working directory under `/tmp/`.
3. Stages the source tarball into the rpmbuild `SOURCES` layout.
4. Generates an RPM `.spec` file with the appropriate metadata and install paths.
5. Invokes `build_rpm.sh` to run `rpmbuild` and produce the RPM.
6. Copies the built RPM to the specified output directory.
7. Cleans up the temporary directory on exit.

## Prerequisites

- `rpmbuild` must be installed.

## Example
```sh
skaliann@sjc-ads-11873 /n/s/xr-appmgr-build (owner-rpm-build-tool)> ./owner-rpm-build.sh --name openr --source /nobackup/skaliann/rpms/openr.tar.gz -v 1.0.1 -r r2 -o /nobackup/skaliann/rpms
==> Working directory: /tmp/owner-rpm-build.EiY7hRsrAg
==> Generated spec file: /tmp/owner-rpm-build.EiY7hRsrAg/build/archives/SPECS/owner-openr-1.0.1-r2.spec
RPM built successfully, copying over the RPMs directory to /root/RPMS
/tmp/owner-rpm-build.EiY7hRsrAg/output:
x86_64

/tmp/owner-rpm-build.EiY7hRsrAg/output/x86_64:
owner-openr-1.0.1-r2.x86_64.rpm
==> RPM created successfully: /nobackup/skaliann/rpms/owner-openr-1.0.1-r2.x86_64.rpm
==> Install prefix: /opt/owner/openr
skaliann@sjc-ads-11873 /n/s/xr-appmgr-build (owner-rpm-build-tool)> rpm -qilp /nobackup/skaliann/rpms/owner-openr-1.0.1-r2.x86_64.rpm
Name        : owner-openr
Version     : 1.0.1
Release     : r2
Architecture: x86_64
Install Date: (not installed)
Group       : 3rd party application
Size        : 102141046
License     : Proprietary
Signature   : (none)
Source RPM  : owner-openr-1.0.1-r2.src.rpm
Build Date  : Tue 17 Feb 2026 01:26:54 PM PST
Build Host  : sjc-ads-11873.cisco.com
Relocations : /
Packager    : xr-appmgr-build
Summary     : owner-openr 1.0.1 compiled for IOS-XR
Description :
RPM built for use with IOS-XR.
/opt/owner/openr
/opt/owner/openr/openr.tar.gz
```
