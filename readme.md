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
3. Commit changes to your branch
4. Go to the [RPM lockfile runner](https://github.com/red-hat-data-services/rpm-lockfile-runner/actions/workflows/rpm-lockfile-runner.yml) actions page and run the workflow, selecting your specific branch
5. After it is complete, you should have an rpms.lock.yaml and ubi.repo commited to your branch
