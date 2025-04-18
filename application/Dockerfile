# ---- Base Node ----
FROM node:18-alpine as base
WORKDIR /app
# Install dependencies only when package files change
COPY backend/package*.json backend/
COPY frontend/package*.json frontend/

# ---- Dependencies ----
# Install backend dependencies
FROM base as backend-deps
WORKDIR /app/backend
RUN npm install
# Install frontend dependencies
FROM base as frontend-deps
WORKDIR /app/frontend
RUN npm install

# ---- Backend Build ----
FROM base as backend-builder
WORKDIR /app/backend
COPY --from=backend-deps /app/backend/node_modules ./node_modules
COPY backend/ ./ 
RUN npm run build

# ---- Frontend Build ----
FROM base as frontend-builder
WORKDIR /app/frontend
COPY --from=frontend-deps /app/frontend/node_modules ./node_modules
COPY frontend/ ./ 
# Pass API URL as build arg (optional, can also be set at runtime)
ARG REACT_APP_API_URL=/api 
RUN npm run build

# ---- Final Backend Image ----
FROM node:18-alpine as final-backend
WORKDIR /app

ENV NODE_ENV=production

# Copy built backend application
COPY --from=backend-builder /app/backend/dist ./dist
COPY --from=backend-builder /app/backend/node_modules ./node_modules
COPY --from=backend-builder /app/backend/package.json ./

# Expose port and start command (adjust port if needed)
EXPOSE 8080 
CMD ["node", "dist/index.js"]

# ---- Final Frontend Image ----
# Use a lightweight nginx server for frontend static files
FROM nginx:1.25-alpine as final-frontend

# Copy built frontend files from the builder stage
COPY --from=frontend-builder /app/frontend/build /usr/share/nginx/html

# Copy nginx config (optional: if you need custom nginx settings)
# COPY nginx.conf /etc/nginx/nginx.conf 

# Expose port 80 (default for nginx)
EXPOSE 80

# Default command starts nginx
CMD ["nginx", "-g", "daemon off;"]

# Note: This Dockerfile creates two separate final images: 
# 'final-backend' and 'final-frontend'. 
# You would build them separately using targets:
# docker build --target final-backend -t your-repo/backend:latest .
# docker build --target final-frontend -t your-repo/frontend:latest . 