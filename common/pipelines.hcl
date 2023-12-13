terraform {
  source = "git::https://github.com/nexient-llc/tf-aws-wrapper_module-codepipelines.git//.?ref=${local.git_tag}"
}

locals {
  inputs = yamldecode(file("${get_terragrunt_dir()}/inputs.yaml"))
  git_tag = local.inputs.git_tag
}

inputs = {
  null_resource_aws_profile         = local.inputs.null_resource_aws_profile
  pipelines                         = local.inputs.pipelines
  build_image                       = local.inputs.build_image
  additional_codebuild_projects     = local.inputs.additional_codebuild_projects
  build_image_pull_credentials_type = local.inputs.build_image_pull_credentials_type

  tags = try(local.inputs.tags, {})
}
