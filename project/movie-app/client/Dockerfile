FROM node:10

ADD . .

RUN CI=true

RUN npm install

EXPOSE 8000

CMD ["npm","start"]