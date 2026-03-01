FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci --silent && npm cache clean --force

EXPOSE 3000

CMD [ "npm", "start" ]
