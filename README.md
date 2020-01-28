# NearbyComputing API Docs

An API documentation generator based on [DociQL](https://github.com/wayfair/dociql)

## Init

Install the required packages:

```sh
npm install
```

## Building the docs

The documentation is generated by querying a running instance of the API Gateway.
The "frontend dev" environment can be used:

```sh
docker-compose -f docker-compose-frontend.yml up -d
```

Once the environment is ready:

```sh
npm run build
```

By default, the output of the build is available in the `public` directory.
