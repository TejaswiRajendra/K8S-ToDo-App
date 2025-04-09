# Use Node.js base image
FROM node:18

# Create app directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy app source
COPY . .

# Expose port and run app
EXPOSE 3000
CMD ["npm", "start"]
