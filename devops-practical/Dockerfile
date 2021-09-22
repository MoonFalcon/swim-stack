FROM node:alpine3.14
WORKDIR /app

# Copying package files as a separate layer for efficiency
COPY package*.json ./
RUN npm install

# Copy app files
COPY . .

# Expose non standard port
EXPOSE 3000
CMD [ "node", "server.js"]

