# Product Management Web Application
 
Github Repo: 
	SSH: git@github.com:uyen2511/DevOps.git
	HTTPS: https://github.com/uyen2511/DevOps.git

## 1. Project Overview
This repository contains the source code and deployment configurations for the mid-term project of the "Software Deployment, Operations and Maintenance" course (502094). The project is a web-based application developed for managing products, including features such as product listing, creation, validation, and file upload handling. 

The purpose of this project is to demonstrate a complete DevOps workflow through three distinct phases
* **Phase 1** Professional Git collaboration, repository management, and Linux automation scripting.
* **Phase 2** Traditional deployment on a bare Ubuntu cloud server (host-based).
* **Phase 3** Modern deployment using Docker and Docker Compose on the same server, followed by a comparative analysis of both approaches.

## 2. Technology Stack
* **Backend** Node.js (Express.js)
* **Frontend** EJS Template Engine, HTML, CSS, JavaScript
* **Database** MongoDB
* **Key Middleware** Express, Multer (for file uploads), validation libraries
* **Process Manager (Phase 2)** PM2
* **Reverse Proxy (Phase 2 & 3)** Nginx
* **Containerization (Phase 3)** Docker, Docker Compose, Docker Hub

## 3. System Architecture
The application follows a standard Model-View-Controller (MVC) architecture. 
* Clients interact with the frontend views rendered by EJS.
* Requests are handled by Nginx acting as a reverse proxy, which forwards them to the Node.js backend.
* The Node.js application securely interacts with a MongoDB persistence layer.
* In Phase 3, this entire architecture is containerized, ensuring the web application and database communicate securely within an isolated Docker bridge network.

## 4. Project Structure
.
├── phase1/             # Phase 1 artifacts (Git workflow, automation scripts)
├── phase2/             # Phase 2 artifacts (Traditional deployment configs)
├── phase3/             # Phase 3 artifacts (Dockerfiles, compose files)
│
├── controllers/        # Business logic for handling requests
├── models/             # Database models (Mongoose schemas)
├── routes/             # Defines application routes
├── services/           # Core services (e.g., database connection logic)
├── validators/         # Input validation logic
├── views/              # EJS templates for the frontend
├── public/             # Static assets (CSS, client-side JS, images)
│   └── uploads/        # Directory for uploaded files (persisted in Phase 3)
│
├── main.js             # Application entry point
├── package.json        # Project metadata and dependencies
├── .gitignore          # Specifies intentionally untracked files to ignore
├── .env                # Environment variables (excluded from version control)
└── README.md           # This file

## 5. Prerequisites

### Local Development
- Node.js (v18 or later recommended)
- npm
- MongoDB (local or cloud instance)
- Git

### For Deployment (Phase 2 & 3)
- Ubuntu cloud server (22.04 LTS or later)
- Registered domain name pointed to server's IP
- Docker and Docker Compose (Phase 3)

## 6. Environment Variables
Due to the evolving architecture across the three phases, the environment variable configurations change accordingly. You must configure the `.env.example` file based on the specific deployment stage you are executing.

### Phase 1 - Local Development
Used for local testing and initial development. The database runs on your local machine.

PORT=3000
NODE_ENV=development

MONGO_URI=mongodb://localhost:27017/products_db
#MONGO_URI=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/products_db

UPLOAD_DIR=./public/uploads
MAX_FILE_SIZE=5242880

#SESSION_SECRET=your-session-secret-key-here
#LOG_LEVEL=debug

### Phase 2 - Traditional Host-Based Deployment
Used when deploying directly on the Ubuntu cloud server. The application runs natively on the host and connects to the host-level database.

PORT=3000
NODE_ENV=production
MONGO_URI=mongodb://localhost:27017/products_db
#MONGO_URI=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/products_db
UPLOAD_DIR=./phase1/src/public/uploads
MAX_FILE_SIZE=5242880
#SESSION_SECRET=your-session-secret-key-here
#LOG_LEVEL=debug

### Phase 3 - Docker Containerized Deployment

PORT=3000
NODE_ENV=production

# MongoDB container credentials (must match docker-compose.yml)
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=secret
MONGO_INITDB_DATABASE=devops

# Connection string using Docker service name
MONGO_URI=mongodb://admin:secret@mongodb:27017/devops?authSource=admin

# Docker Hub image
IMAGE_NAME=pupu2005/devops-app
IMAGE_TAG=latest

# Port mapping on host (8080 mapped to container's 3000)
HOST_PORT=8080

UPLOAD_PATH=/app/phase1/src/public/uploads
MAX_FILE_SIZE=10485760

MONGO_VOLUME=mongodb_data
UPLOADS_VOLUME=./phase1/src/public/uploads

## 7. Local Development Setup
Follow these steps to get the application running on your local machine.

Clone the repository

git clone https://github.com/uyen2511/DevOps.git
cd DevOps
Install dependencies

npm install
Configure environment variables
Create a .env file as shown in Section 6 and fill in your MongoDB connection string.

Ensure MongoDB is running
Make sure your local MongoDB instance is active.

Run the application

Bash
node main.js
For development with auto-restart on file changes, you can use npx nodemon main.js.

Access the application
Open your browser and navigate to http://localhost:3000.

## 8. Automation Scripts (Phase 1)
The phase1/scripts/ directory contains shell scripts to automate the setup of a production environment on a fresh Ubuntu server.

setup.sh automates the following tasks

Updates the package list and upgrades existing packages.

Installs system dependencies (e.g., Node.js, Nginx, build tools).

Creates necessary directory structures for logs, uploads, and application data.

How to execute the script

Bash
chmod +x phase1/scripts/setup.sh
sudo ./phase1/scripts/setup.sh
This script is written with clear comments and avoids hard-coded credentials, making it a reliable foundation for Phase 2 deployment.

## 9. Deployment Overview
This project will be deployed in two distinct phases on an Ubuntu cloud server. All configurations, evidence, and documentation for each phase are stored in the corresponding phase1/, phase2/, and phase3/ directories.

### 9.1 Phase 2 Traditional Deployment (Host-based)
In this phase, the application runs natively on the host operating system.

Runtime Preparation The setup.sh script is used to install Node.js, Nginx, and other dependencies.

Process Management The application is managed by PM2 to ensure it restarts automatically after failures or server reboots.

Reverse Proxy & HTTPS Nginx is configured as a reverse proxy to route traffic from ports 80/443 to the Node.js application. A Let's Encrypt SSL certificate is obtained using Certbot to enable HTTPS.

Database The application connects to a MongoDB instance securely.

### 9.2 Phase 3 Containerized Deployment (Docker)
In this phase, the entire application stack is migrated to Docker containers, orchestrated by Docker Compose.

Web Application Container The Node.js app is containerized using a production-ready Dockerfile. The image is built and pushed to Docker Hub, then pulled onto the server.

Database Container A MongoDB container (using the official mongo:6.0 image) runs alongside the web container.

Orchestration Docker Compose defines the web and db services, including a dedicated network, persistent volumes for database files and user uploads, and restart policies.

Reverse Proxy The host-level Nginx from Phase 2 is reconfigured to proxy requests to the containerized web service exposed port. HTTPS remains fully functional.

Resilience Docker's restart: always policies ensure the entire stack recovers automatically from container crashes and full server reboots.

- **Volume for uploads**: `./phase1/src/public/uploads:/app/phase1/src/public/uploads` (bind mount)
- **Volume for database**: `mongodb_data:/data/db` (named volume)
- **Reverse proxy**: Nginx upstream updated to `http://localhost:8080`

## 10. Important Notes
Security Never commit sensitive information to the repository. The .gitignore file is configured to prevent this.

Uploads Directory The public/uploads/ folder is excluded from version control but is persisted in Phase 3 using Docker volumes.

Evidence All screenshots, configuration files, and logs demonstrating the successful completion of each phase are stored in the respective phase directories, as required by the project specification.

## 11. Evidence
- [Docker Hub Repository](https://hub.docker.com/r/pupu2005/devops-app)
- [Live Application](https://orangecaramel.online)
- Phases screenshots are stored in each phase's directory 
