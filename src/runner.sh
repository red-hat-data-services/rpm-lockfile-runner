#!/bin/bash
set -euo pipefail

export CONFIG_FILE=config.yaml


trap "rm *.tmp" EXIT

indices=$(yq '.stages[] | path[1]' $CONFIG_FILE)
if [ "$(uname -s)" = "Darwin" ]; then
  function sed {
    gsed "$@"
  }
fi

# loop over the stages and generate lockfiles for each stage
for i in $indices; do
  export i
  export TEMP_RPMS_IN="rpms.in.yaml.${i}.tmp"
  export TEMP_UBI_REPO="ubi.repo.${i}.tmp"
  export TEMP_LOCKFILE="rpms.lock.yaml.${i}.tmp"
  
  # generate an rpms.lock.yaml file 
  yq -n '.contentOrigin.repofiles[0] = strenv(TEMP_UBI_REPO)' > $TEMP_RPMS_IN
  export STAGE=$(yq '.stages[strenv(i)]' $CONFIG_FILE)
  yq -i '.arches = load(strenv(CONFIG_FILE)).arches' $TEMP_RPMS_IN
  yq -i '.packages = env(STAGE).packages' $TEMP_RPMS_IN

  BASE_IMAGE=$(yq -n 'env(STAGE).image')

  # trick to avoid having to login
  BASE_IMAGE=$(echo "$BASE_IMAGE" | sed 's/registry\.redhat\.io/registry.access.redhat.com/')
  export BASE_IMAGE
  yq -i '.context.image = strenv(BASE_IMAGE)' $TEMP_RPMS_IN
  # cat $TEMP_RPMS_IN
  
  # produce an ubi.repo file
  podman run -it $BASE_IMAGE cat /etc/yum.repos.d/ubi.repo > $TEMP_UBI_REPO
  # Enable all listed repos
  sed -Ei 's/^enabled = 0/enabled = 1/' $TEMP_UBI_REPO

  # add for-$basearch in the appropriate spots 
  # needs to match https://security.access.redhat.com/data/metrics/repository-to-cpe.json
  sed -Ei 's/ubi-([0-9]+)-codeready-builder/codeready-builder-for-ubi-\1-$basearch/' $TEMP_UBI_REPO
  sed -Ei 's/\[ubi-([0-9]+)/[ubi-\1-for-$basearch/' $TEMP_UBI_REPO
  
  # cat $TEMP_UBI_REPO
  container_dir='/work'
  podman run --rm -v "${PWD}:${container_dir}" \
    localhost/rpm-lockfile-prototype:latest \
    --outfile "$container_dir/$TEMP_LOCKFILE" \
    "$container_dir/$TEMP_RPMS_IN"
  
done


# consolidate ubi.repo files
cat ubi.repo.*.tmp > ubi.repo

# consolidate rpms.lock.yaml files
export ARCHES=$(yq '.arches[]' $CONFIG_FILE)

ls -al

cp rpms.lock.yaml.0.tmp rpms.lock.yaml

yq -i 'with(.arches[]; .packages |= [] | .source |= [] | .module_metadata |= [])' rpms.lock.yaml

for arch in $ARCHES; do
  export arch
  export arch_data="${arch}.tmp"
  yq ea '(.arches[] | select(.arch==strenv(arch))) 
    as $item ireduce ({}; . *+ $item )' rpms.lock.yaml.*.tmp > $arch_data
    yq -i 'with(.arches[]; select(.arch==strenv(arch)) |= load(strenv(arch_data)))' rpms.lock.yaml
done
echo "final lockfile has been saved to rpms.lock.yaml"
# cat rpms.lock.yaml


echo "validating repoids with source of truth"
export VALID_REPOS_FILE=repository-to-cpe.tmp
REPO_SOURCE_OF_TRUTH=https://security.access.redhat.com/data/metrics/repository-to-cpe.json
curl "$REPO_SOURCE_OF_TRUTH" | jq -r '.data|keys[]' > $VALID_REPOS_FILE
REPO_IDS=$(yq '.arches[].packages[].repoid' rpms.lock.yaml)
INVALID_REPOS=""
for repo_id in $REPO_IDS; do
  match=$(grep -x "$repo_id" $VALID_REPOS_FILE)
  if [ -z $match ]; then
    INVALID_REPOS=$(echo -e "$INVALID_REPOS\n$repo_id")
  fi
done

if [ -n "$INVALID_REPOS" ]; then
  echo "The following repos were not found in $REPO_SOURCE_OF_TRUTH:"
  echo $INVALID_REPOS
  exit 1
fi

echo "repo validation success"
echo "exiting"

