terraform {
  source = "git::https://github.com/nexient-llc/tf-aws-wrapper_module-bulk_lambda_function.git//.?ref=${local.git_tag}"
}

locals {
  inputs  = yamldecode(file("${get_terragrunt_dir()}/inputs.yaml"))
  git_tag = local.inputs.git_tag
}

inputs = {
  bulk_lambda_functions = local.inputs.bulk_lambda_functions

  tags = try(local.inputs.tags, {})
}
