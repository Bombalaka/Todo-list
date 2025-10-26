📋 Complete Todo App Checklist - React + Kubernetes
Project Goal: Build a full-stack Todo app with React frontend, .NET backend, MongoDB, deployed to AWS EKS

Phase 1: Frontend (React + Vite) ⚛️
Step 1.1: Setup React Project

 Navigate to project root

bashcd todo-app

 Create webapp folder with Vite + React + TypeScript

bashnpm create vite@latest webapp -- --template react-ts

 Navigate into webapp

bashcd webapp

 Install dependencies

bashnpm install

 Install Axios for API calls

bashnpm install axios

 Test it runs locally

bashnpm run dev
# Open http://localhost:5173 - should see Vite + React welcome page

 Stop the server (Ctrl+C)


Step 1.2: Create Todo UI Component

 Replace src/App.tsx with the following code:

typescriptimport { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Get API URL from environment variable
const API_URL = (window as any).ENV?.VITE_API_URL || 
                 import.meta.env.VITE_API_URL || 
                 'http://localhost:8080';

interface Task {
  id: string;
  title: string;
  isCompleted: boolean;
}

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [newTask, setNewTask] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Fetch tasks on load
  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/api/tasks`);
      setTasks(response.data);
      setError('');
    } catch (err) {
      setError('Cannot connect to backend. Is it running?');
      console.error('Error fetching tasks:', err);
    } finally {
      setLoading(false);
    }
  };

  const addTask = async () => {
    if (!newTask.trim()) return;

    try {
      const response = await axios.post(`${API_URL}/api/tasks`, {
        title: newTask
      });
      setTasks([...tasks, response.data]);
      setNewTask('');
      setError('');
    } catch (err) {
      setError('Failed to add task');
      console.error('Error adding task:', err);
    }
  };

  const deleteTask = async (id: string) => {
    try {
      await axios.delete(`${API_URL}/api/tasks/${id}`);
      setTasks(tasks.filter(t => t.id !== id));
      setError('');
    } catch (err) {
      setError('Failed to delete task');
      console.error('Error deleting task:', err);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      addTask();
    }
  };

  return (
    <div className="app-container">
      <div className="todo-card">
        <h1 className="title">📝 My Todo List</h1>

        {/* Error message */}
        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        {/* Add task form */}
        <div className="add-task-form">
          <input
            type="text"
            value={newTask}
            onChange={(e) => setNewTask(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="What needs to be done?"
            className="task-input"
          />
          <button onClick={addTask} className="add-button">
            Add Task
          </button>
        </div>

        {/* Task list */}
        {loading ? (
          <p className="loading-text">Loading tasks...</p>
        ) : tasks.length === 0 ? (
          <p className="empty-text">
            No tasks yet! Add one above to get started.
          </p>
        ) : (
          <ul className="task-list">
            {tasks.map(task => (
              <li key={task.id} className="task-item">
                <span className="task-title">{task.title}</span>
                <button
                  onClick={() => deleteTask(task.id)}
                  className="delete-button"
                >
                  Delete
                </button>
              </li>
            ))}
          </ul>
        )}

        {/* Footer */}
        <div className="footer">
          Total tasks: {tasks.length}
        </div>
      </div>
    </div>
  );
}

export default App;

Step 1.3: Create Styles

 Replace src/App.css with the following:

css* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

.app-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem 1rem;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.todo-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
  padding: 2rem;
  max-width: 600px;
  width: 100%;
}

.title {
  font-size: 2rem;
  color: #333;
  margin-bottom: 1.5rem;
  text-align: center;
}

.error-message {
  background-color: #fee;
  border: 1px solid #fcc;
  color: #c33;
  padding: 1rem;
  border-radius: 6px;
  margin-bottom: 1rem;
}

.add-task-form {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.task-input {
  flex: 1;
  border: 2px solid #ddd;
  border-radius: 6px;
  padding: 0.75rem 1rem;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.task-input:focus {
  outline: none;
  border-color: #667eea;
}

.add-button {
  background: #667eea;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;
}

.add-button:hover {
  background: #5568d3;
}

.loading-text,
.empty-text {
  text-align: center;
  color: #999;
  padding: 2rem 0;
}

.task-list {
  list-style: none;
}

.task-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  border: 1px solid #eee;
  border-radius: 6px;
  margin-bottom: 0.5rem;
  transition: background 0.2s;
}

.task-item:hover {
  background: #f9f9f9;
}

.task-title {
  color: #333;
  font-size: 1rem;
  flex: 1;
}

.delete-button {
  background: transparent;
  color: #e74c3c;
  border: none;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background 0.2s;
}

.delete-button:hover {
  background: #fee;
}

.footer {
  text-align: center;
  color: #999;
  font-size: 0.875rem;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #eee;
}

 Update src/index.css to be minimal:

css:root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
}

Step 1.4: Create Environment Files

 Create .env.local for local development:

bashecho "VITE_API_URL=http://localhost:8080" > .env.local

 Create public/env-config.js for runtime configuration:

javascriptwindow.ENV = {
  VITE_API_URL: 'http://localhost:8080'
};

 Update index.html to load env-config.js:

html<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Todo App</title>
    <script src="/env-config.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>

Step 1.5: Update Vite Configuration

 Update vite.config.ts:

typescriptimport { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
  },
  preview: {
    host: true,
    port: 3000,
  }
})

Step 1.6: Test Frontend Locally

 Start React app

bashnpm run dev

 Open browser at http://localhost:5173
 Verify you see the todo UI with purple gradient
 Expected: "Cannot connect to backend" error (normal - backend not running yet)
 Stop the server (Ctrl+C)


Step 1.7: Create Dockerfile

 Create Dockerfile in webapp folder:

dockerfile# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create runtime config
RUN echo 'window.ENV = { VITE_API_URL: "http://backend-service" };' > /usr/share/nginx/html/env-config.js

# Expose port
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

Step 1.8: Create Nginx Configuration

 Create nginx.conf in webapp folder:

nginxserver {
    listen 3000;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

---

### Step 1.9: Create .dockerignore

- [ ] Create `.dockerignore` in webapp folder:
```
node_modules
dist
.git
.env.local
.env.production
README.md
*.log

Step 1.10: Test Docker Build

 Build Docker image

bashdocker build -t todo-webapp:local .

 Run Docker container

bashdocker run -p 3000:3000 todo-webapp:local

 Open browser at http://localhost:3000
 Verify todo UI is running in container
 Stop container (Ctrl+C)


Phase 2: Backend (.NET API) ⚙️
Step 2.1: Setup .NET Project

 Navigate back to project root

bashcd ../..

 Create backend folder

bashmkdir backend && cd backend

 Create .NET Web API

bashdotnet new webapi -n TodoApi -minimal

 Create solution file

bashdotnet new sln -n TodoApi
dotnet sln add TodoApi/TodoApi.csproj

 Test it runs

bashcd TodoApi
dotnet run
# Should see: "Now listening on: http://localhost:5000"

 Stop the server (Ctrl+C)


Step 2.2: Add MongoDB Driver

 Add MongoDB package

bashdotnet add package MongoDB.Driver

Step 2.3: Create Program.cs

 Navigate to backend/TodoApi/
 Replace Program.cs with:

csharpusing MongoDB.Driver;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

var builder = WebApplication.CreateBuilder(args);

// CORS configuration
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// MongoDB configuration
var mongoConnectionString = builder.Configuration.GetValue<string>("MongoDB:ConnectionString") 
    ?? "mongodb://localhost:27017";
var mongoDatabaseName = builder.Configuration.GetValue<string>("MongoDB:DatabaseName") 
    ?? "todoDB";

var mongoClient = new MongoClient(mongoConnectionString);
var database = mongoClient.GetDatabase(mongoDatabaseName);
var tasksCollection = database.GetCollection<TodoTask>("tasks");

builder.Services.AddSingleton(tasksCollection);

var app = builder.Build();

app.UseCors("AllowAll");

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// GET /api/tasks
app.MapGet("/api/tasks", async (IMongoCollection<TodoTask> collection) =>
{
    var tasks = await collection.Find(_ => true).ToListAsync();
    return Results.Ok(tasks);
});

// GET /api/tasks/{id}
app.MapGet("/api/tasks/{id}", async (string id, IMongoCollection<TodoTask> collection) =>
{
    var filter = Builders<TodoTask>.Filter.Eq(t => t.Id, id);
    var task = await collection.Find(filter).FirstOrDefaultAsync();
    
    return task is not null 
        ? Results.Ok(task) 
        : Results.NotFound(new { message = "Task not found" });
});

// POST /api/tasks
app.MapPost("/api/tasks", async (CreateTodoRequest request, IMongoCollection<TodoTask> collection) =>
{
    if (string.IsNullOrWhiteSpace(request.Title))
    {
        return Results.BadRequest(new { message = "Title is required" });
    }

    var task = new TodoTask
    {
        Id = Guid.NewGuid().ToString(),
        Title = request.Title,
        IsCompleted = false,
        CreatedAt = DateTime.UtcNow
    };

    await collection.InsertOneAsync(task);
    
    return Results.Created($"/api/tasks/{task.Id}", task);
});

// PUT /api/tasks/{id}
app.MapPut("/api/tasks/{id}", async (string id, UpdateTodoRequest request, IMongoCollection<TodoTask> collection) =>
{
    if (string.IsNullOrWhiteSpace(request.Title))
    {
        return Results.BadRequest(new { message = "Title is required" });
    }

    var filter = Builders<TodoTask>.Filter.Eq(t => t.Id, id);
    var update = Builders<TodoTask>.Update
        .Set(t => t.Title, request.Title)
        .Set(t => t.IsCompleted, request.IsCompleted);

    var result = await collection.UpdateOneAsync(filter, update);
    
    return result.MatchedCount > 0 
        ? Results.NoContent() 
        : Results.NotFound(new { message = "Task not found" });
});

// DELETE /api/tasks/{id}
app.MapDelete("/api/tasks/{id}", async (string id, IMongoCollection<TodoTask> collection) =>
{
    var filter = Builders<TodoTask>.Filter.Eq(t => t.Id, id);
    var result = await collection.DeleteOneAsync(filter);
    
    return result.DeletedCount > 0 
        ? Results.NoContent() 
        : Results.NotFound(new { message = "Task not found" });
});

app.Run();

// Models
public record TodoTask
{
    [BsonId]
    [BsonRepresentation(BsonType.String)]
    public string Id { get; init; } = string.Empty;
    
    [BsonElement("title")]
    public string Title { get; init; } = string.Empty;
    
    [BsonElement("isCompleted")]
    public bool IsCompleted { get; init; }
    
    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; init; }
}

public record CreateTodoRequest(string Title);

public record UpdateTodoRequest(string Title, bool IsCompleted);

Step 2.4: Update appsettings.json

 Update appsettings.json:

json{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "MongoDB": {
    "ConnectionString": "mongodb://localhost:27017",
    "DatabaseName": "todoDB"
  }
}

Step 2.5: Create Backend Dockerfile

 Navigate to backend/ folder
 Create Dockerfile:

dockerfile# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# Copy csproj and restore
COPY TodoApi/TodoApi.csproj TodoApi/
RUN dotnet restore TodoApi/TodoApi.csproj

# Copy everything and build
COPY TodoApi/ TodoApi/
WORKDIR /src/TodoApi
RUN dotnet build -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

WORKDIR /app

COPY --from=publish /app/publish .

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "TodoApi.dll"]
```

---

### Step 2.6: Create Backend .dockerignore

- [ ] Create `.dockerignore` in backend folder:
```
bin
obj
.git
.vs
.vscode
*.user

Phase 3: Local Testing with Docker Compose 🐳
Step 3.1: Create docker-compose.yaml

 Navigate to project root (todo-app/)
 Create docker-compose.yaml:

yamlversion: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: todo-mongodb
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
    volumes:
      - mongodb-data:/data/db
    networks:
      - todo-network
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  mongo-express:
    image: mongo-express:latest
    container_name: todo-mongo-express
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: password123
      ME_CONFIG_MONGODB_SERVER: mongodb
      ME_CONFIG_MONGODB_PORT: "27017"
    depends_on:
      mongodb:
        condition: service_healthy
    networks:
      - todo-network

  backend:
    build: ./backend
    container_name: todo-backend
    ports:
      - "8080:8080"
    environment:
      ASPNETCORE_URLS: http://+:8080
      MongoDB__ConnectionString: "mongodb://admin:password123@mongodb:27017"
      MongoDB__DatabaseName: "todoDB"
    depends_on:
      mongodb:
        condition: service_healthy
    networks:
      - todo-network

  webapp:
    build: ./webapp
    container_name: todo-webapp
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - todo-network

networks:
  todo-network:
    driver: bridge

volumes:
  mongodb-data:

Step 3.2: Test Everything Locally

 Build and start all containers

bashdocker-compose up --build

 Wait for all services to start (watch logs)
 Open frontend: http://localhost:3000
 Test adding tasks (e.g., "Buy milk", "Walk dog")
 Test deleting a task
 Refresh page - tasks should persist
 Check MongoDB UI: http://localhost:8081 (login: admin/password123)
 Navigate to todoDB → tasks to see stored data
 Test backend directly: http://localhost:8080/api/tasks
 Check logs for errors

bashdocker-compose logs webapp
docker-compose logs backend
docker-compose logs mongodb

 Stop everything (Ctrl+C)

bashdocker-compose down

Phase 4: AWS Setup (ECR + EKS) ☁️
Step 4.1: Setup AWS CLI

 Install AWS CLI if not installed

bash# macOS
brew install awscli

# Windows: Download from aws.amazon.com
# Linux
apt install awscli

 Configure AWS credentials

bashaws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Output format: json

Step 4.2: Create ECR Repositories

 Create backend repository

bashaws ecr create-repository --repository-name todo-backend --region us-east-1

 Create frontend repository

bashaws ecr create-repository --repository-name todo-webapp --region us-east-1

 Note down repository URIs (format: 123456789012.dkr.ecr.us-east-1.amazonaws.com/todo-backend)


Step 4.3: Login to ECR

 Get AWS account ID

bashaws sts get-caller-identity --query Account --output text

 Login to ECR (replace with your account ID)

bashaws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

Step 4.4: Build and Push Images

 Set environment variables (replace with your values)

bashexport AWS_ACCOUNT_ID=123456789012
export AWS_REGION=us-east-1

 Build and push backend

bashcd backend
docker build -t todo-backend:latest .
docker tag todo-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-backend:latest

 Build and push frontend

bashcd ../webapp
docker build -t todo-webapp:latest .
docker tag todo-webapp:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-webapp:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-webapp:latest

 Verify images in ECR

bashaws ecr list-images --repository-name todo-backend --region us-east-1
aws ecr list-images --repository-name todo-webapp --region us-east-1

Step 4.5: Create EKS Cluster

 Install eksctl

bash# macOS
brew install eksctl

# Linux/Windows: Check eksctl.io

 Create EKS cluster (takes 15-20 minutes)

basheksctl create cluster \
  --name todo-app-cluster \
  --region us-east-1 \
  --nodegroup-name todo-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

 Verify cluster is ready

bashkubectl get nodes
# Should see 2 nodes in Ready state

 Configure kubectl context

bashaws eks update-kubeconfig --name todo-app-cluster --region us-east-1

Phase 5: Kubernetes Manifests 📝
Step 5.1: Create Manifest Structure

 Navigate to project root

bashcd ../..

 Create manifest folders

bashmkdir -p manifests/mongodb
mkdir -p manifests/mongo-express
mkdir -p manifests/backend
mkdir -p manifests/webapp

Step 5.2: Create Namespace

 Create manifests/namespace.yaml:

yamlapiVersion: v1
kind: Namespace
metadata:
  name: todo-app
  labels:
    name: todo-app

Step 5.3: Create MongoDB Secret

 Create manifests/mongodb/mongodb-secret.yaml:

yamlapiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
  namespace: todo-app
type: Opaque
data:
  # echo -n 'admin' | base64
  mongo-root-username: YWRtaW4=
  # echo -n 'password123' | base64
  mongo-root-password: cGFzc3dvcmQxMjM=

Step 5.4: Create MongoDB PVC

 Create manifests/mongodb/mongodb-pvc.yaml:

yamlapiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: todo-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: gp2

Step 5.5: Create MongoDB StatefulSet

 Create manifests/mongodb/mongodb-statefulset.yaml:

yamlapiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: todo-app
spec:
  type: ClusterIP
  clusterIP: None
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
  namespace: todo-app
spec:
  serviceName: mongodb-service
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-password
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
      volumes:
      - name: mongodb-storage
        persistentVolumeClaim:
          claimName: mongodb-pvc

Step 5.6: Create Mongo Express

 Create manifests/mongo-express/mongo-express.yaml:

yamlapiVersion: v1
kind: Service
metadata:
  name: mongo-express-service
  namespace: todo-app
spec:
  type: ClusterIP
  selector:
    app: mongo-express
  ports:
  - port: 8081
    targetPort: 8081

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-express
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-express
  template:
    metadata:
      labels:
        app: mongo-express
    spec:
      containers:
      - name: mongo-express
        image: mongo-express:latest
        ports:
        - containerPort: 8081
        env:
        - name: ME_CONFIG_MONGODB_ADMINUSERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-username
        - name: ME_CONFIG_MONGODB_ADMINPASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-password
        - name: ME_CONFIG_MONGODB_SERVER
          value: mongodb-service
        - name: ME_CONFIG_MONGODB_PORT
          value: "27017"

Step 5.7: Create Backend Deployment

 Create manifests/backend/backend.yaml:
 IMPORTANT: Replace YOUR_AWS_ACCOUNT with your actual AWS account ID

yamlapiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: todo-app
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: YOUR_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/todo-backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: ASPNETCORE_URLS
          value: "http://+:8080"
        - name: MongoDB__ConnectionString
          value: "mongodb://$(MONGO_USERNAME):$(MONGO_PASSWORD)@mongodb-service:27017"
        - name: MongoDB__DatabaseName
          value: "todoDB"
        - name: MONGO_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-username
        - name: MONGO_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-password
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

Step 5.8: Create Frontend Deployment

 Create manifests/webapp/webapp.yaml:
 IMPORTANT: Replace YOUR_AWS_ACCOUNT with your actual AWS account ID

yamlapiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: todo-app
spec:
  type: ClusterIP
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 3000

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: YOUR_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/todo-webapp:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

Step 5.9: Create Ingress

 Create manifests/ingress.yaml:

yamlapiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  namespace: todo-app
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
      - path: /mongo-express
        pathType: Prefix
        backend:
          service:
            name: mongo-express-service
            port:
              number: 8081
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80

Step 5.10: Install AWS Load Balancer Controller

 Download IAM policy

bashcurl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

 Create IAM policy (replace YOUR_ACCOUNT_ID)

bashaws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json

 Create IAM service account (replace YOUR_ACCOUNT_ID)

basheksctl create iamserviceaccount \
  --cluster=todo-app-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::YOUR_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

 Install controller

bashkubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=todo-app-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

 Verify controller is running

bashkubectl get deployment -n kube-system aws-load-balancer-controller

Phase 6: Deploy to Kubernetes 🚀
Step 6.1: Deploy All Resources

 Create namespace

bashkubectl apply -f manifests/namespace.yaml

 Create MongoDB secret

bashkubectl apply -f manifests/mongodb/mongodb-secret.yaml

 Create storage

bashkubectl apply -f manifests/mongodb/mongodb-pvc.yaml

 Deploy MongoDB

bashkubectl apply -f manifests/mongodb/mongodb-statefulset.yaml

 Wait for MongoDB to be ready

bashkubectl wait --for=condition=ready pod -l app=mongodb -n todo-app --timeout=180s

 Deploy Mongo Express

bashkubectl apply -f manifests/mongo-express/mongo-express.yaml

 Deploy Backend

bashkubectl apply -f manifests/backend/backend.yaml

 Deploy Frontend

bashkubectl apply -f manifests/webapp/webapp.yaml

 Deploy Ingress

bashkubectl apply -f manifests/ingress.yaml

Step 6.2: Verify Deployment

 Check all resources

bashkubectl get all -n todo-app

 Check pods are running

bashkubectl get pods -n todo-app
# All should show "Running"

 Check services

bashkubectl get svc -n todo-app

 Get Ingress URL

bashkubectl get ingress -n todo-app
# Look for ADDRESS column

 Check logs if issues

bashkubectl logs -l app=backend -n todo-app
kubectl logs -l app=webapp -n todo-app
kubectl logs -l app=mongodb -n todo-app

Step 6.3: Access Your Application

 Get Load Balancer URL

bashkubectl get ingress todo-app-ingress -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

 Wait 2-3 minutes for DNS propagation
 Open in browser: http://[YOUR-LOAD-BALANCER-URL]
 Test adding tasks
 Test deleting tasks
 Check database UI (optional): http://[YOUR-LOAD-BALANCER-URL]/mongo-express


Phase 7: Testing & Scaling 🧪
Step 7.1: Scale Applications

 Scale backend to 3 replicas

bashkubectl scale deployment backend --replicas=3 -n todo-app

 Watch pods scaling

bashkubectl get pods -n todo-app -w

 Scale frontend to 3 replicas

bashkubectl scale deployment webapp --replicas=3 -n todo-app

 Check pod distribution

bashkubectl get pods -n todo-app -o wide

Step 7.2: Test Pod Recovery

 Delete a backend pod

bashkubectl delete pod [backend-pod-name] -n todo-app

 Watch it automatically restart

bashkubectl get pods -n todo-app -w

 Verify app still works in browser


Step 7.3: Test Rolling Update

 Make a small change to frontend (e.g., change title in App.tsx)
 Build new image with v2 tag

bashcd webapp
docker build -t todo-webapp:v2 .

 Push to ECR

bashdocker tag todo-webapp:v2 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-webapp:v2
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-webapp:v2

 Update deployment

bashkubectl set image deployment/webapp webapp=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/todo-webapp:v2 -n todo-app

 Watch rolling update

bashkubectl rollout status deployment/webapp -n todo-app

 Verify change in browser


Step 7.4: View Logs

 View backend logs

bashkubectl logs -l app=backend -n todo-app --tail=50

 View frontend logs

bashkubectl logs -l app=webapp -n todo-app --tail=50

 Follow logs in real-time

bashkubectl logs -f [pod-name] -n todo-app

Troubleshooting 🔧
Common Issues

 Pods not starting: Check pod description

bashkubectl describe pod [pod-name] -n todo-app

 Can't pull images: Verify ECR permissions

bashaws ecr get-login-password --region us-east-1

 MongoDB connection issues: Check from backend pod

bashkubectl exec -it [backend-pod] -n todo-app -- /bin/sh
# Inside: curl http://mongodb-service:27017

 Load Balancer not created: Check Ingress events

bashkubectl describe ingress todo-app-ingress -n todo-app

 Need to start over: Delete namespace and redeploy

bashkubectl delete namespace todo-app
```

---

## Project Structure 📁
```
todo-app/
├── webapp/                     # React frontend
│   ├── src/
│   │   ├── App.tsx
│   │   ├── App.css
│   │   └── main.tsx
│   ├── public/
│   │   └── env-config.js
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── backend/                    # .NET API
│   ├── TodoApi/
│   │   ├── Program.cs
│   │   └── TodoApi.csproj
│   └── Dockerfile
│
├── manifests/                  # Kubernetes manifests
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-pvc.yaml
│   │   └── mongodb-statefulset.yaml
│   ├── mongo-express/
│   │   └── mongo-express.yaml
│   ├── backend/
│   │   └── backend.yaml
│   ├── webapp/
│   │   └── webapp.yaml
│   └── ingress.yaml
│
└── docker-compose.yaml

What You Built ✅

✅ React frontend with TypeScript
✅ .NET 8 Minimal API backend
✅ MongoDB database with persistent storage
✅ Mongo Express database UI
✅ Docker containerization
✅ Docker Compose for local development
✅ AWS ECR for container registry
✅ AWS EKS Kubernetes cluster
✅ Kubernetes Deployments, Services, Ingress
✅ StatefulSet for database
✅ Health checks and probes
✅ Horizontal scaling
✅ Rolling updates
✅ AWS Application Load Balancer


Next Steps 🚀

 Add authentication (JWT tokens)
 Add task completion toggle
 Add task editing
 Add CI/CD pipeline (GitHub Actions)
 Add monitoring (Prometheus/Grafana)
 Add logging (ELK stack)
 Implement autoscaling
 Add HTTPS with SSL certificate
 Refactor backend to Clean Architecture

