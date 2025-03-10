#!/bin/bash
#
#
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail

# Argparse via https://stackoverflow.com/a/33826763
workdir=0
debug=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -w|--workdir) workdir="$2"; shift ;;
        -d|--debug) debug=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# For debugging purposes, uncomment this and get every executed bash command printed to the console for tracing.
if [[ $debug -eq 1 ]] ; then
    set -x
    echo "DEBUG: Printing env-vars"
    env | sort
    echo "------------------------"
fi
#######
#
IFS=$'\n\t'
# Paths
if [[ $workdir -eq 0 ]]; then
    this_script_dir=$(dirname "$0")
else
    this_script_dir=$workdir
fi
cd "$this_script_dir" || exit 1
repo_basedir=$(git rev-parse --show-toplevel)
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/portable.sh
# Source bash logging tools
#
# shellcheck disable=1090,1091
source "$repo_basedir"/scripts/logger.bash

#####################
#####################
#####################
#
# This script assumes that the repo.config file is present at the top level of the ops-repo
# This script assumes that the docker-compose.yml from the osparc-simcore repo is present at the repo_basedir.
#
# Loads configurations variables
# See https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
if [ ! -f "$repo_basedir"/.config.location ]
then
    echo "$repo_basedir/repo.config" > "$repo_basedir"/.config.location # .config.location needs to have exactly one line
fi
repo_config=$(cat "$repo_basedir"/.config.location)
set -o allexport
# shellcheck disable=1090
source "$repo_config"
set +o allexport
#
cd "$repo_basedir"
#
python -c "import urllib.request,os,sys,urllib; f = open(os.path.basename(sys.argv[1]), 'wb'); f.write(urllib.request.urlopen(sys.argv[1]).read()); f.close();" https://github.com/mikefarah/yq/releases/download/v4.29.2/yq_linux_amd64
mv yq_linux_amd64 yq
chmod +x yq
_yq=$(realpath yq)
export _yq
pushd services/simcore
rm .env 2>/dev/null || true
make compose-"${OSPARC_DEPLOYMENT_TARGET}"
mv .env .env.platform
python envsubst_escape_dollar_sign.py .env.platform .env.nosub
envsubst < .env.nosub > .env
cp .env ..
cp ../../docker-compose.yml ./docker-compose.simcore.yml

"$repo_basedir"/scripts/docker-stack-config.bash -e .env docker-compose.simcore.yml docker-compose.deploy.yml > ../../stack.yml
#
#
### Cleanup
popd
if [[ $debug -eq 1 ]] ; then
    set +x
fi
