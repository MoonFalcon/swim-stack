# syntax=docker/dockerfile:1

FROM node:12.18.1

WORKDIR /app

# Copying package files as a separate layer for efficiency
COPY ["package.json", "package-lock.json*", "./"]

RUN npm install

# Copy app files
COPY . .

# Expose non standard port
EXPOSE 3000

# CMD [ "node", "server.js"]
CMD [ "node", "server.js" ]

