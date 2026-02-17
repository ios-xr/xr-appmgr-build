#!/bin/bash
#
# owner-rpm-build.sh
#
# Wrapper script that generates an RPM spec file and invokes build_rpm.sh
# to produce an owner RPM package for IOS-XR appmgr.
#
# Usage:
#   owner-rpm-build.sh -n <name> -v <version> -r <release> -s <source_path> -o <outputdir> [-a <arch>]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Required:
    -n, --name          Name of the rpm (will be prefixed with "owner-")
    -v, --version       Version string (e.g. 1.0.0)
    -r, --release       Release string (e.g. r1)
    -s, --source        Path to the docker image .tar.gz file
    -o, --outputdir     Directory where the final RPM will be placed

Optional:
    -a, --arch          Target architecture (default: x86_64)
    -h, --help          Show this help message

Example:
    $(basename "$0") -n fibagent -v 1.0.0 -r r1 -s /path/to/fibagent.tar.gz -o ./output
    -> Produces: owner-fibagent-1.0.0-r1.x86_64.rpm
       Installed to: /opt/owner/fibagent/
EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
NAME=""
VERSION=""
RELEASE=""
SOURCE=""
OUTPUTDIR=""
ARCH="x86_64"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)        NAME="$2";        shift 2 ;;
        -v|--version)     VERSION="$2";     shift 2 ;;
        -r|--release)     RELEASE="$2";     shift 2 ;;
        -s|--source)      SOURCE="$2";      shift 2 ;;
        -o|--outputdir)   OUTPUTDIR="$2";   shift 2 ;;
        -a|--arch)        ARCH="$2";        shift 2 ;;
        -h|--help)        usage ;;
        *)                echo "Unknown option: $1"; usage ;;
    esac
done

# ---------------------------------------------------------------------------
# Validate required arguments
# ---------------------------------------------------------------------------
error=0
if [[ -z "$NAME" ]]; then
    echo "Error: --name is required"; error=1
fi
if [[ -z "$VERSION" ]]; then
    echo "Error: --version is required"; error=1
fi
if [[ -z "$RELEASE" ]]; then
    echo "Error: --release is required"; error=1
fi
if [[ -z "$SOURCE" ]]; then
    echo "Error: --source is required"; error=1
fi
if [[ -n "$SOURCE" && ! -f "$SOURCE" ]]; then
    echo "Error: source file '$SOURCE' does not exist"; error=1
fi
if [[ -n "$SOURCE" && ! "$SOURCE" =~ \.tar\.gz$ ]]; then
    echo "Error: source file must be a .tar.gz file (got: '$SOURCE')"; error=1
fi
if [[ -n "$SOURCE" && -n "$NAME" ]]; then
    _src_basename="$(basename "$SOURCE")"
    _src_name="${_src_basename%%.*}"
    if [[ "$_src_name" != "$NAME" ]]; then
        echo "Error: source file name '${_src_basename}' does not match --name '${NAME}' (expected '${NAME}.tar.gz')"; error=1
    fi
fi
if [[ -z "$OUTPUTDIR" ]]; then
    echo "Error: --outputdir is required"; error=1
fi
if [[ $error -ne 0 ]]; then
    echo ""
    usage
fi

RPM_NAME="owner-${NAME}"
FULL_NAME="${RPM_NAME}-${VERSION}-${RELEASE}"
INSTALL_PREFIX="/opt/owner/${NAME}"

# ---------------------------------------------------------------------------
# Create a temporary working directory
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d /tmp/owner-rpm-build.XXXXXXXXXX)
trap "rm -rf ${TMPDIR}" EXIT

echo "==> Working directory: ${TMPDIR}"

# ---------------------------------------------------------------------------
# build_rpm.sh hardcodes _topdir as "$PWD/build/archives/", so we set up
# the TMPDIR with that exact structure and cd into it before calling the
# build script.
# ---------------------------------------------------------------------------
TOPDIR="${TMPDIR}/build/archives"
mkdir -p "${TOPDIR}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# ---------------------------------------------------------------------------
# Prepare source tarball layout:
#   <FULL_NAME>/sources/<name>/  <- docker image tar.gz file
# ---------------------------------------------------------------------------
SOURCE="$(realpath "${SOURCE}")"
SOURCE_BASENAME="$(basename "${SOURCE}")"

STAGING="${TMPDIR}/staging/${FULL_NAME}"
mkdir -p "${STAGING}/sources/${NAME}"
cp "${SOURCE}" "${STAGING}/sources/${NAME}/${SOURCE_BASENAME}"

# Also create empty conventional dirs expected by rpmbuild %setup
mkdir -p "${STAGING}/configs" "${STAGING}/data" "${STAGING}/service"

# Create the source tarball
tar czf "${TOPDIR}/SOURCES/${FULL_NAME}.tar.gz" -C "${TMPDIR}/staging" "${FULL_NAME}"

# ---------------------------------------------------------------------------
# Generate the spec file
# ---------------------------------------------------------------------------
SPEC_FILE="${TOPDIR}/SPECS/${FULL_NAME}.spec"

cat > "${SPEC_FILE}" <<SPEC
Name: ${RPM_NAME}
Version: ${VERSION}
Release: ${RELEASE}
License: Proprietary
Packager: xr-appmgr-build
SOURCE0 : ${FULL_NAME}.tar.gz
Group: 3rd party application
Summary: ${RPM_NAME} ${VERSION} compiled for IOS-XR

Prefix: /

%description
RPM built for use with IOS-XR.

%prep
%setup -q -n ${FULL_NAME}

%install
mkdir -p %{buildroot}${INSTALL_PREFIX}
cp sources/${NAME}/${SOURCE_BASENAME} %{buildroot}${INSTALL_PREFIX}/

%files
%defattr(-,root,root)
${INSTALL_PREFIX}
${INSTALL_PREFIX}/${SOURCE_BASENAME}
SPEC

echo "==> Generated spec file: ${SPEC_FILE}"

# ---------------------------------------------------------------------------
# Invoke build_rpm.sh from inside TMPDIR so that $PWD/build/archives/
# resolves to our rpmbuild tree.
# ---------------------------------------------------------------------------
RPM_OUT="${TOPDIR}/RPMS"
OUTPUT_DIR="${TMPDIR}/output"
mkdir -p "${OUTPUT_DIR}"

pushd "${TMPDIR}" > /dev/null

"${SCRIPT_DIR}/build_rpm.sh" \
    --target "${ARCH}" \
    --spec-file "${SPEC_FILE}" \
    --source-dir "${TOPDIR}/SOURCES" \
    --rpm-dir "${RPM_OUT}" \
    --output-dir "${OUTPUT_DIR}"

popd > /dev/null

# ---------------------------------------------------------------------------
# Move the built RPM(s) to the requested output directory
# ---------------------------------------------------------------------------
mkdir -p "${OUTPUTDIR}"

BUILT_RPM=$(find "${OUTPUT_DIR}" -name "*.rpm" -type f | head -1)

if [[ -z "${BUILT_RPM}" ]]; then
    echo "Error: No RPM found after build. Check build log."
    exit 1
fi

cp "${BUILT_RPM}" "${OUTPUTDIR}/"
FINAL_RPM="${OUTPUTDIR}/$(basename "${BUILT_RPM}")"

echo "==> RPM created successfully: ${FINAL_RPM}"
echo "==> Install prefix: ${INSTALL_PREFIX}"
