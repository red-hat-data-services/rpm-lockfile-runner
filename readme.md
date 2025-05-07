# RPM Lockfile Updater

This is a tool that you can use to create the RPM lockfiles that are used by Hermeto. Two main use cases:

- For users who have had difficulty using the [RPM lockfile prototype](https://github.com/konflux-ci/rpm-lockfile-prototype) tool
- For multi-stage builds, automating the combination of rpms.lock.yaml files between stages

## Instructions

1. Create a new branch on this repo. 
2. Edit `config.yaml` with the settings that you want:
    - `arches` - specify which cpu architectures
    - `stages` - if the build dockerfile has multiple stages, include the stages that install packages via DNF.
    - `image` - Add the image URI for each relevant stage
    - `packages` - Add the packages that are installed in each stage.

    Example config:

    ```
    arches:
    - x86_64
    - s390x
    stages:
    - image: registry.redhat.io/ubi8/go-toolset:1.22@sha256:a1a37882bbcf1c0f1115d478d5ea9f74b496b8c753d5e4e431a70786e2dbcbfc
      packages:
      - cmake
      - clang
      - openssl
    - image: registry.redhat.io/ubi8/ubi-minimal@sha256:33161cf5ec11ea13bfe60cad64f56a3aa4d893852e8ec44b2fd2a6b40cc38539
      packages:
      - ca-certificates
      - wget
    ```

3. Commit changes to your branch. Once you commit, a github actions will automatically start
4. After it is complete, you should have an `rpms.lock.yaml` and `ubi.repo` commited to your branch that you can copy to wherever you need
5. If something went wrong, you can go to the [RPM lockfile runner](https://github.com/red-hat-data-services/rpm-lockfile-runner/actions/workflows/rpm-lockfile-runner.yml) actions page and check logs or manually run the workflow, selecting your specific branch
