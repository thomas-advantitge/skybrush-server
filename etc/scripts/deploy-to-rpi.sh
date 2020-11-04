#!/bin/bash
#
# Script that builds and deploys the Skybrush Server along with a console
# frontend straight to a Raspberry Pi

set -e

if [ -f /proc/cpuinfo ]; then
  RUNNING_ON_RPI=`grep Hardware /proc/cpuinfo | grep -c BCM`
else
  RUNNING_ON_RPI=0
fi

export LANG=C LC_ALL=C

if [ $RUNNING_ON_RPI -lt 1 ]; then
  # We are not on the Raspberry Pi yet so just copy ourselves to the RPi
  TARGET="$1"
  if [ "x$TARGET" = x ]; then
    echo "Usage: $0 USERNAME@IP"
    echo ""
    echo "where USERNAME@IP is the username and IP address of the Raspberry Pi."
    echo "We assume that public key authentication is already set up; if it is"
    echo "not, run 'ssh-copy-id USERNAME@IP'"
    exit 1
  fi

  set -x
  scp -q "$0" "$TARGET":.
  set +x

  ssh "$TARGET" /bin/bash <<EOF
chmod +x ./deploy-to-rpi.sh
EOF

  echo "Script was copied to $TARGET:$0"
  echo "Now log in and execute it."

  exit
fi

##############################################################################

## From oow on, this bit of code is supposed to be exected on the RPi only

# Read the bash profile
source ${HOME}/.profile

# Check whether we have set up PyArmor already
if [ ! -d ${HOME}/.pyarmor ]; then
  echo "PyArmor not set up on the RPi yet. Please copy your PyArmor license file "
  echo "and private capsule to ~/.pyarmor/"
  exit 1
fi

# Check whether poetry is installed
if [ ! -d ${HOME}/.poetry ]; then
  echo "Poetry not installed yet. Please install Poetry first with this command:"
  echo ""
  echo "$ curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -"
  echo ""
  echo "After installation, log out, log in again and then set your username and"
  echo "password to the CollMot private repository with:"
  echo ""
  echo "poetry config http-basic.collmot <your-username>"
  echo ""
  echo "To allow this script to run in unsupervised mode, you should use an"
  echo "unencrypted keyring (unless you use a GUI on the RPi, which you shouldn't."
  echo ""
  echo "Create or edit ~/.local/share/python_keyring/keyringrc.cfg so that it has"
  echo "the following contents _before_ setting up the credentials:"
  echo ""
  echo "[backend]"
  echo "default-keyring=keyrings.alt.file.PlaintextKeyring"
  echo ""
  echo "You might also need to install python-keyring.alt"
  exit 1
fi

# WORK_DIR=$(mktemp -d -t build-XXXXXXXXXX --tmpdir=.)
WORK_DIR=work
POETRY=${HOME}/.poetry/bin/poetry

echo "Work directory: ${WORK_DIR}"

if [ ! -d "${WORK_DIR}" ]; then
  mkdir -p "${WORK_DIR}"
fi
cd "${WORK_DIR}"

if [ ! -d skybrush-server ]; then
    git clone git@git.collmot.com:collmot/flockwave-server.git skybrush-server
fi

cd skybrush-server
git pull

etc/scripts/build-pyarmored-dist.sh

# rm -rf "${WORK_DIR}"

