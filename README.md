# NearbyComputing API Docs

An API documentation generator based on [DociQL](https://github.com/wayfair/dociql)

## Usage

The Docker image defined in `Dockerfile` is used as the base image for the Concourse task `ci/generate-docs`,
which is referred to in the Concourse pipeline in the related repo [nearbyone-docs](https://github.com/nbycomp/nearbyone-docs/).

Changes should be made to `config.yml` in this repo when changes are made to [our GraphQL schema](https://github.com/nbycomp/graphql-hello-world/).

## Building the docs

The documentation is generated from the result of concatenating all the .graphql schema files in
graphql-hello-world/graphql-backend/schema/\*.graphql.

This can also be done locally:

```sh
cat /path/to/graphql-hello-world/graphql-backend/schema/*.graphql > /tmp/schema.graphql
```

This file can be bind-mounted into the task image, and the docs will be built:

```sh
podman run -v /tmp/schema.graphql:/tmp/schema.graphql:z registry.nearbycomputing.com/nbycomp/core/api-gateway/docs-task
```

## Debugging

If you get an error like:

```sh
/node_modules/dociql/app/dociql/compose-paths.js:42
            field: target.name,
                          ^

TypeError: Cannot read properties of undefined (reading 'name')
```

You may have an endpoint referenced in your config.yml that no longer exists, or has an incorrect path.
