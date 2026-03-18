Product Management Web Application

1. Project Overview

This repository contains the source code and deployment configurations for the mid-term project of the "Software Deployment, Operations and Maintenance" course (502094). The project is a web-based application developed for managing products, including features such as product listing, creation, validation, and file upload handling. The system follows a typical MVC structure.

The purpose of this project is to demonstrate a complete DevOps workflow through three distinct phases:
1.  **Phase 1:** Professional Git collaboration, repository management, and Linux automation scripting.
2.  **Phase 2:** Traditional deployment on a bare Ubuntu cloud server (host-based).
3.  **Phase 3:** Modern deployment using Docker and Docker Compose on the same server, followed by a comparative analysis of both approaches.

2. Technology Stack

*   **Backend:** Node.js (Express.js)
*   **Frontend:** EJS Template Engine, HTML, CSS, JavaScript
*   **Database:** MongoDB
*   **Key Middleware:** Express, Multer (for file uploads), validation libraries
*   **Process Manager (Phase 2):** PM2 / systemd (TBD)
*   **Reverse Proxy (Phase 2 & 3):** Nginx
*   **Containerization (Phase 3):** Docker, Docker Compose, Docker Hub

3. Project Structure
.
├── phase1/ # Phase 1 artifacts (Git workflow, automation scripts)
├── phase2/ # Phase 2 artifacts (Traditional deployment configs)
├── phase3/ # Phase 3 artifacts (Dockerfiles, compose files)
│
├── controllers/ # Business logic for handling requests
├── models/ # Database models (Mongoose schemas)
├── routes/ # Defines application routes
├── services/ # Core services (e.g., database connection logic)
├── validators/ # Input validation logic
├── views/ # EJS templates for the frontend
├── public/ # Static assets (CSS, client-side JS, images)
│ └── uploads/ # Directory for uploaded files (persisted in Phase 3)
│
├── main.js # Application entry point
├── package.json # Project metadata and dependencies
├── .gitignore # Specifies intentionally untracked files to ignore
├── .env # Environment variables (excluded from version control)
└── README.md # This file

text

4. Prerequisites

Before you can run this project locally or deploy it, ensure you have the following installed:

*   **Local Development:**
    *   [Node.js](https://nodejs.org/) (v18 or later recommended)
    *   [npm](https://www.npmjs.com/) (usually comes with Node.js)
    *   [MongoDB](https://www.mongodb.com/) (local or cloud instance)
    *   [Git](https://git-scm.com/)

*   **For Deployment (Phase 2 & 3):**
    *   An Ubuntu cloud server (22.04 LTS or later)
    *   A registered domain name (pointed to the server's IP)
    *   (For Phase 3) [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/)

5. Environment Variables

Create a `.env` file in the root directory. Use the following template:

```env
PORT=3000
MONGO_URI=your_mongodb_connection_string
# Add any other environment variables your app needs
Important: The .env file contains sensitive information and is excluded from version control by our .gitignore. Never commit this file to the repository.

6. Local Development Setup
Follow these steps to get the application running on your local machine.

Clone the repository:

bash
git clone <your-repository-url>
cd <your-repository-name>
Install dependencies:

bash
npm install
Configure environment variables:
Create a .env file as shown in Section 5 and fill in your MongoDB connection string.

Ensure MongoDB is running:
Make sure your local MongoDB instance is active (e.g., sudo systemctl start mongod on Linux, or run it as a service on Windows/macOS).

Run the application:

bash
node main.js
For development with auto-restart on file changes, you can use npx nodemon main.js.

Access the application:
Open your browser and navigate to http://localhost:3000.

7. Key Features
Product Management: Full CRUD (Create, Read, Update, Delete) operations for products.

Input Validation: Server-side validation for product data using validation libraries.

File Upload Handling: Supports uploading product images/files using Multer middleware.

Dynamic UI Rendering: Server-side rendering with EJS templates for a dynamic user experience.

Database Integration: Persistent data storage with MongoDB.

8. Automation Scripts (Phase 1)
The /phase1/scripts/ directory (or /scripts/ at the root) contains shell scripts to automate the setup of a production environment on a Ubuntu server.

setup.sh: This script is designed to be run on a fresh Ubuntu server. It automates the following tasks:

Updates the package list and upgrades existing packages.

Installs system dependencies (e.g., Node.js, Nginx, build tools).

Creates necessary directory structures for logs, uploads, and application data.

The script is written with clear comments and avoids hard-coded credentials, making it a reliable foundation for Phase 2 deployment.

9. Deployment Overview
This project will be deployed in two distinct phases on an Ubuntu cloud server. All configurations, evidence, and documentation for each phase are stored in the corresponding phase1/, phase2/, and phase3/ directories.

9.1 Phase 2: Traditional Deployment (Host-based)
In this phase, the application runs natively on the host operating system.

Runtime Preparation: The setup.sh script (from Phase 1) is used to install Node.js, Nginx, and other dependencies.

Process Management: The application will be managed by a process supervisor like PM2 or a systemd service to ensure it restarts automatically after failures or server reboots.

Reverse Proxy & HTTPS: Nginx will be configured as a reverse proxy to route traffic from ports 80/443 to the Node.js application. A Let's Encrypt SSL certificate will be obtained using Certbot to enable HTTPS.

Database: The application will connect to a MongoDB instance (either installed on the same host or a cloud-managed service like MongoDB Atlas).

9.2 Phase 3: Containerized Deployment (Docker)
In this phase, the entire application stack is migrated to Docker containers, orchestrated by Docker Compose.

Web Application Container: The Node.js app is containerized using a production-ready Dockerfile. The image is built and pushed to Docker Hub, then pulled onto the server (no source code is built directly on the server).

Database Container: A MongoDB container (using the official mongo:6.0 image) runs alongside the web container, replacing any external or host-based database.

Orchestration: Docker Compose defines the web and db services, including:

A dedicated network for internal communication between containers.

Volumes for persistent data (database files and uploaded files in public/uploads).

Environment variables for configuration.

Restart policies to ensure high availability.

Reverse Proxy: The host-level Nginx from Phase 2 is reconfigured to proxy requests to the containerized web service (e.g., http://localhost:3000 or the container's IP/port). HTTPS remains fully functional.

Resilience: Docker's restart policies and Docker daemon auto-start ensure the entire stack recovers automatically from container crashes, Docker daemon restarts, and full server reboots.

10. Important Notes
Security: Never commit sensitive information (like .env files, passwords, or API keys) to the repository. The .gitignore file is configured to prevent this.

MongoDB: Ensure your MongoDB instance is running and accessible via the MONGO_URI provided in the .env file before starting the application.

Uploads Directory: The public/uploads/ folder is excluded from version control but will be persisted in Phase 3 using Docker volumes.

Evidence: All screenshots, configuration files, and logs demonstrating the successful completion of each phase are stored in the respective phase1/, phase2/, and phase3/ directories, as required by the project specification.

Domain Name: A registered domain name is required for Phase 2 and 3 to enable HTTPS. Affordable options (e.g., from Hostinger.vn) are acceptable.