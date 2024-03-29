FROM node:18-bullseye

COPY package-lock.json package.json /
RUN npm ci

COPY config.yml /

CMD [ "npm", "run", "build" ]
