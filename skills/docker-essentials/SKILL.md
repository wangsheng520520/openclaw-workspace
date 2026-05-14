---
name: docker-essentials
description: 当用户提到"运行Docker容器"、"查看Docker日志"、"构建Docker镜像"、"管理Docker网络/卷"、"清理Docker空间"、"使用docker-compose"、"进入容器内部"或"排查容器问题"时使用。提供容器生命周期管理、镜像操作、日志调试、Compose编排及危险操作确认等完整工作流。
homepage: https://docs.docker.com/
metadata: {"clawdbot":{"emoji":"🐳","requires":{"bins":["docker"]},"triggers":["docker","容器","镜像","docker-compose","构建镜像","查看日志","进入容器","清理Docker"]}}
---

# Docker Essentials

Essential Docker commands for container and image management.

## ⚠️ 前置检查 (Prerequisites)

> 在执行任何 Docker 操作前，系统会自动检查以下条件：

```bash
# 1. 检查 Docker 是否安装
docker --version

# 2. 检查 Docker 服务是否运行
docker info

# 3. 权限检查 (Linux/macOS)
# 如果没有权限，尝试：
sudo docker ps  # 或将当前用户加入 docker 组
# sudo usermod -aG docker $USER && newgrp docker

# 4. 磁盘空间检查
docker system df
# ⚠️ 如果磁盘满，执行：docker system prune
```

**异常处理：**
- **Docker 未安装** → 提示安装： `curl -fsSL https://get.docker.com | sh` (Linux) 或从 docker.com 下载 (Windows/Mac)
- **权限不足** → 提示使用 `sudo` 或将用户加入 `docker` 组
- **磁盘空间不足** → 提示执行 `docker system prune` 或清理无用资源
- **Docker 服务未运行** → 提示启动服务：`sudo systemctl start docker`

## Container Lifecycle

### Running containers
```bash
# Run container from image
docker run nginx

# Run in background (detached)
docker run -d nginx

# Run with name
docker run --name my-nginx -d nginx

# Run with port mapping
docker run -p 8080:80 -d nginx

# Run with environment variables
docker run -e MY_VAR=value -d app

# Run with volume mount
docker run -v /host/path:/container/path -d app

# Run with auto-remove on exit
docker run --rm alpine echo "Hello"

# Interactive terminal
docker run -it ubuntu bash
```

### Managing containers
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop container
docker stop container_name

# Start stopped container
docker start container_name

# Restart container
docker restart container_name

# Remove container
# ⚠️ 危险操作：删除前确认容器名或ID
docker rm container_name

# Force remove running container
# ⚠️ 危险操作：强制删除运行中的容器，可能导致数据丢失
# 执行前请确认：docker ps 确认容器状态
docker rm -f container_name

# Remove all stopped containers
# ⚠️ 危险操作：批量删除已停止容器，确认无误后执行
docker container prune
```

## Container Inspection & Debugging

### Viewing logs
```bash
# Show logs
docker logs container_name

# Follow logs (like tail -f)
docker logs -f container_name

# Last 100 lines
docker logs --tail 100 container_name

# Logs with timestamps
docker logs -t container_name
```

### Executing commands
```bash
# Execute command in running container
docker exec container_name ls -la

# Interactive shell
docker exec -it container_name bash

# Execute as specific user
docker exec -u root -it container_name bash

# Execute with environment variable
docker exec -e VAR=value container_name env
```

### Inspection
```bash
# Inspect container details
docker inspect container_name

# Get specific field (JSON path)
docker inspect -f '{{.NetworkSettings.IPAddress}}' container_name

# View container stats
docker stats

# View specific container stats
docker stats container_name

# View processes in container
docker top container_name
```

## Image Management

### Building images
```bash
# Build from Dockerfile
docker build -t myapp:1.0 .

# Build with custom Dockerfile
docker build -f Dockerfile.dev -t myapp:dev .

# Build with build args
docker build --build-arg VERSION=1.0 -t myapp .

# Build without cache
docker build --no-cache -t myapp .
```

### Managing images
```bash
# List images
docker images

# Pull image from registry
docker pull nginx:latest

# Tag image
docker tag myapp:1.0 myapp:latest

# Push to registry
docker push myrepo/myapp:1.0

# Remove image
# ⚠️ 危险操作：删除镜像前确认镜像名称（删除后无法恢复）
docker rmi image_name

# Remove unused images
# ⚠️ 危险操作：清理未使用的镜像，确认无误后执行
docker image prune

# Remove all unused images
# ⚠️ 危险操作：删除所有未使用的镜像（包括未打标签的），此操作不可逆
docker image prune -a
```

## Docker Compose

### Basic operations
```bash
# Start services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs

# Follow logs for specific service
docker-compose logs -f web

# Scale service
docker-compose up -d --scale web=3
```

### Service management
```bash
# List services
docker-compose ps

# Execute command in service
docker-compose exec web bash

# Restart service
docker-compose restart web

# Rebuild service
docker-compose build web

# Rebuild and restart
docker-compose up -d --build
```

## Networking

```bash
# List networks
docker network ls

# Create network
docker network create mynetwork

# Connect container to network
docker network connect mynetwork container_name

# Disconnect from network
docker network disconnect mynetwork container_name

# Inspect network
docker network inspect mynetwork

# Remove network
# ⚠️ 危险操作：删除网络前确认无容器依赖此网络
docker network rm mynetwork
```

## Volumes

```bash
# List volumes
docker volume ls

# Create volume
docker volume create myvolume

# Inspect volume
docker volume inspect myvolume

# Remove volume
# ⚠️ 危险操作：删除卷会永久丢失数据，确认数据已备份
docker volume rm myvolume

# Remove unused volumes
# ⚠️ 危险操作：清理未使用卷，确认无误后执行
docker volume prune

# Run with volume
docker run -v myvolume:/data -d app
```

## System Management

```bash
# View disk usage
docker system df

# Clean up everything unused
# ⚠️ 危险操作：清理所有未使用的构建缓存、网络、已停止容器
docker system prune

# Clean up including unused images
# ⚠️ 危险操作：删除所有未使用的镜像，此操作不可逆
docker system prune -a

# Clean up including volumes
# ⚠️ 危险操作：清理所有未使用的卷，会永久删除数据！
docker system prune --volumes

# Show Docker info
docker info

# Show Docker version
docker version
```

## Common Workflows

**Development container:**
```bash
docker run -it --rm \
  -v $(pwd):/app \
  -w /app \
  -p 3000:3000 \
  node:18 \
  npm run dev
```

**Database container:**
```bash
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15
```

**Quick debugging:**
```bash
# Shell into running container
docker exec -it container_name sh

# Copy file from container
docker cp container_name:/path/to/file ./local/path

# Copy file to container
docker cp ./local/file container_name:/path/in/container
```

**Multi-stage build:**
```dockerfile
# Dockerfile
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

## Useful Flags

**`docker run` flags:**
- `-d`: Detached mode (background)
- `-it`: Interactive terminal
- `-p`: Port mapping (host:container)
- `-v`: Volume mount
- `-e`: Environment variable
- `--name`: Container name
- `--rm`: Auto-remove on exit
- `--network`: Connect to network

**`docker exec` flags:**
- `-it`: Interactive terminal
- `-u`: User
- `-w`: Working directory

## Tips

- Use `.dockerignore` to exclude files from build context
- Combine `RUN` commands in Dockerfile to reduce layers
- Use multi-stage builds to reduce image size
- Always tag your images with versions
- Use `--rm` for one-off containers
- Use `docker-compose` for multi-container apps
- Clean up regularly with `docker system prune`

## Documentation

Official docs: https://docs.docker.com/
Dockerfile reference: https://docs.docker.com/engine/reference/builder/
Compose file reference: https://docs.docker.com/compose/compose-file/
