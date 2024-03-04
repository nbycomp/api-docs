local action = import 'action.libsonnet';
local job = import 'job.libsonnet';
local resource = import 'resource.libsonnet';
local resource_type = import 'resource_type.libsonnet';

local api_docs_repo = 'git@github.com:nbycomp/api-docs.git';
local api_gw_repo = 'git@github.com:nbycomp/graphql-hello-world.git';
local api_docs_task_repository = 'registry.nearbycomputing.com/nbycomp/core/api-gateway/docs-task';

local task_concat_schema = {
  task: 'concat-schema',
  config: {
    platform: 'linux',
    image_resource: {
      type: 'registry-image',
      source: { repository: 'busybox' },
    },
    inputs: [{ name: 'api-gw' }],
    outputs: [{ name: 'schema' }],
    run: { path: 'sh', args: [
      '-c',
      'cat api-gw/graphql-backend/schema/*.graphql > schema/schema.graphql',
    ] },
  },
};

{
  resource_types: [
    resource_type.pull_request,
  ],

  resources: [
    resource.repo_ci_tasks,
    resource.repo_pipeline(api_docs_repo),
    resource.repo('api-docs', api_docs_repo),
    resource.repo('api-docs-no-html', api_docs_repo, { ignore_paths: ['public'] }),
    resource.repo('api-docs-html', api_docs_repo, { paths: ['public'] }),
    resource.repo('api-gw', api_gw_repo, { paths: ['graphql-backend'] }),
    resource.image('api-docs-task', api_docs_task_repository, 'latest'),
    resource.pr('nbycomp/graphql-hello-world', { paths: ['graphql-backend'] }) { name: 'api-gw-pr' },
  ],

  jobs: [
    job.update_pipeline,
    {
      name: 'api-docs-task',
      public: true,
      serial: true,
      plan: [
        {
          in_parallel: [
            action.get_ci_tasks,
            {
              get: 'repo',
              resource: 'api-docs-no-html',
              trigger: true,
            },
          ],
        },
        action.build,
        {
          put: 'api-docs-task',
          params: {
            image: 'image/image.tar',
          },
        },
      ],
    },
    {
      name: 'test-api-gateway',
      public: true,
      plan: [
        {
          in_parallel: [
            action.get_ci_tasks,
            { get: 'pr', resource: 'api-gw-pr', trigger: true },
            { get: 'api-docs' },
            {
              get: 'api-docs-task',
              passed: ['api-docs-task'],
            },
          ],
        },
      ] + action.with_set_pr('generate-api-docs', [
        step { input_mapping: { 'api-gw': 'pr' } }
        for step in [
          task_concat_schema,
          {
            task: 'generate-docs',
            file: 'api-docs/ci/generate-docs.yml',
            image: 'api-docs-task',
          },
        ]
      ], 'api-gw-pr'),
    },
    {
      name: 'api-docs',
      public: true,
      serial: true,
      plan: [
        {
          in_parallel: [
            action.get_ci_tasks,
            {
              get: 'api-gw',
              trigger: true,
            },
            {
              get: 'repo',
              resource: 'api-docs',
            },
            {
              get: 'api-docs-task',
              trigger: true,
              passed: [
                'api-docs-task',
              ],
            },
          ],
        },
        task_concat_schema,
        {
          task: 'generate-docs',
          file: 'repo/ci/generate-docs.yml',
          image: 'api-docs-task',
        },
        {
          task: 'update-repo',
          file: 'repo/ci/update-repo.yml',
          input_mapping: {
            'api-docs-repo': 'repo',
          },
        },
        {
          put: 'api-docs-html',
          params: {
            repository: 'updated-repo',
          },
        },
      ],
    },
  ],
}
