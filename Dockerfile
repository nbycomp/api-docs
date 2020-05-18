FROM node:13-alpine3.11

COPY package-lock.json package.json /
RUN npm ci

COPY config.yml /

CMD [ "npm", "run", "build" ]
