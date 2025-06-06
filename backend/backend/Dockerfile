# Use Node.js 16 as the base image
FROM node:16-slim

# Create app directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy app source
COPY . .

# Create startup script
RUN echo '#!/bin/sh\n\necho "Initializing database..."\nnode models/init-db.js\necho "Starting server..."\nnpm start' > start.sh && \
    chmod +x start.sh

# Expose port
EXPOSE 3000

# Start the application using the startup script
CMD ["./start.sh"] 