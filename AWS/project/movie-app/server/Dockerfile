FROM node:10

ADD . .

RUN CI=true

RUN npm install

EXPOSE 3000

CMD [ "node", "index.js" ]