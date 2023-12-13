# Terragrunt for CodePipelines

This directory will deploy terragrunt configuration files to provision a CodePipeline for this service.

## Apply the module

```shell
# navigate to the environment directory
cd ./env/root/us-east-2/000
terragrunt init
terragrunt apply -auto-approve
```

## Additional CodeBuild Projects

The `additional_codebuild_projects` variable allows the ability to create additional codebuild projects not associated with a pipeline. These can be used for various activities such as triggering other pipelines. 

## CodePipelines

The `pipelines` variable will contain all the pipelines that should be created for this service. Each defined pipeline is a seperate CodePipeline.
```
pipelines:
  - name: "pr_event"
    ...
    ...
  - name: "qa"
    ...
    ...
```

Within each pipeline, You must define a `source_stage` and `create_s3_source` must be `true` if you want CodePipeline to create the source s3 bucket. 

For all other stages, they must be defined under the `stages` key under each pipeline. Currently acceptable stage providers are `CodeBuild` and `Manual`. 

Example of CodeBuild Stage
```
  - stage_name: "Deployment"
    name: "Deployment"
    category: "Build"
    provider: "CodeBuild"
    project_name: "tg_deploy"
    buildspec: "buildspec.yml"
    configuration:
      EnvironmentVariables: |
        [{"name":"CAF_CODEBUILD_ACTION","value":"terragrunt_deploy","type":"PLAINTEXT"},{"name":"GIT_TOKEN_SM_ARN","value":"arn:aws:secretsmanager:us-east-2:123456789012:secret:bitbucket/http_access_token","type":"PLAINTEXT"},{"name":"GIT_USER_SM_ARN","value":"arn:aws:secretsmanager:us-east-2:123456789012:secret:bitbucket/service_user","type":"PLAINTEXT"},{"name":"TARGETENV","value":"qa","type":"PLAINTEXT"},{"name":"ROLE_TO_ASSUME","value":"arn:aws:iam::123456789012:role/platform_tg_iam-useast2-qa-000-deploy_role-000","type":"PLAINTEXT"}]
    input_artifacts: ["SourceArtifact"]
    codebuild_iam: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": ["sts:AssumeRole"],
            "Effect": "Allow",
            "Resource": "arn:aws:iam::123456789012:role/platform_tg_iam-useast2-qa-000-deploy_role-000"
          }
        ]
      }
```

If a manual staged is defined, by leaving the configuration key within that stage empty, you can add a key `approval_sns_subscribers` at the pipeline defined level to create an SNS topic and add email subscribers to it. 

Example of Manual Stage
```
  - stage_name: "Manual-Approval"
    name: "Manual-Approval"
    category: "Approval"
    provider: "Manual"
    configuration: {}
```

Example with SNS subscribers. 
```
  - name: "qa"
    ...
    approval_sns_subscribers:
      - protocol: "email"
        endpoint: "john.doe@example.com"
      - protocol: "email"
        endpoint: "jane.doe@example.com"
    ...
    stages:
      ...
      - stage_name: "Manual-Approval"
        name: "Manual-Approval"
        category: "Approval"
        provider: "Manual"
        configuration: {}
      ...
```
