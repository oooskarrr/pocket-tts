# Docker Compose Setup Summary

This document provides an overview of the Docker Compose setup added to Pocket TTS for Dokploy deployment.

## Files Created/Modified

### 1. `docker-compose.yml` (Created)
**Purpose**: Main Docker Compose configuration for Dokploy deployment.

**Key Features**:
- Uses existing `Dockerfile` for building the image
- Exposes port 8000 for FastAPI server
- Named volume `pocket-tts-cache` for persisting model downloads
- Health check using Python's urllib (no curl dependency)
- `PYTHONUNBUFFERED=1` for proper log streaming
- Restart policy: `unless-stopped`

**Why This Configuration**:
- **Named Volume**: Ensures the ~200MB of model weights persist across deployments
- **Health Check**: Allows Dokploy to monitor service health automatically
- **No Traefik Labels**: Dokploy's domain management handles routing automatically

### 2. `.dockerignore` (Created)
**Purpose**: Excludes unnecessary files from Docker build context.

**Excludes**:
- Git files, virtual environments, Python cache
- Tests, documentation, CI/CD configs
- Development files (AGENTS.md, CONTRIBUTING.md, pre-commit configs)
- IDE files, OS files, build artifacts
- Keeps only essential files for running the application

**Benefit**: Faster builds and smaller Docker images.

### 3. `.env.example` (Created)
**Purpose**: Template for environment variables.

**Documents**:
- Current supported variables
- Future extensibility for customization
- Comments explaining each variable's purpose

### 4. `DEPLOYMENT.md` (Created)
**Purpose**: Comprehensive Dokploy deployment guide.

**Sections**:
- Prerequisites and Quick Start
- Step-by-step Dokploy configuration
- Domain setup with native Dokploy domain management
- Environment variable configuration
- Service usage (web interface, API, health check)
- Monitoring and logging
- Webhook auto-deployment
- Troubleshooting guide
- Advanced configuration options

### 5. `DOCKER_QUICKSTART.md` (Created)
**Purpose**: Quick reference for common Docker Compose operations.

**Contents**:
- File overview table
- Quick commands (up, logs, down)
- Service details and configuration
- Resource requirements
- First run expectations
- Access methods
- Troubleshooting quick reference

### 6. `DEPLOYMENT_CHECKLIST.md` (Created)
**Purpose**: Step-by-step verification checklist for deployments.

**Checklist Categories**:
- Pre-deployment verification
- Dokploy setup
- Domain configuration
- Deployment
- Post-deployment verification
- Monitoring & maintenance
- Auto-deployment setup
- Troubleshooting steps

### 7. `README.md` (Modified)
**Changes**: Added new "Deployment with Docker" section with:
- Dokploy deployment reference
- Link to DEPLOYMENT.md
- Manual Docker usage example

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Dokploy Server                        │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Docker Compose Application               │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────────┐ │   │
│  │  │           pocket-tts Container                 │ │   │
│  │  │  - FastAPI Server (port 8000)                  │ │   │
│  │  │  - PyTorch TTS Model                           │ │   │
│  │  │  - Web UI                                      │ │   │
│  │  └────────────────────────────────────────────────┘ │   │
│  │                      ▲                               │   │
│  │                      │                               │   │
│  │  ┌───────────────────┴───────────────────────────┐ │   │
│  │  │     pocket-tts-cache (Named Volume)           │ │   │
│  │  │  - Model weights (~200MB)                      │ │   │
│  │  │  - Tokenizer models                           │ │   │
│  │  │  - Voice embeddings                           │ │   │
│  │  └───────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────┘   │
│                      ▲                                       │
│                      │                                       │
│  ┌───────────────────┴─────────────────────────────────────┐ │
│  │              Traefik (Reverse Proxy)                     │ │
│  │  - SSL/TLS termination                                   │ │
│  │  - Domain routing                                        │ │
│  │  - Load balancing                                        │ │
│  └──────────────────────────────────────────────────────────┘ │
│                      ▲                                       │
│                      │                                       │
│                  Internet                                    │
│           https://your-domain.com                            │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Named Volume for Cache
**Decision**: Use Docker named volume instead of bind mount.

**Rationale**:
- Named volumes are Docker-managed and persist across container lifecycle
- Supports Dokploy's Volume Backups feature
- Better for automated backup strategies
- More portable across deployments

### 2. No Traefik Labels in Compose
**Decision**: Don't manually add Traefik labels.

**Rationale**:
- Dokploy's native domain management is simpler and more maintainable
- Labels are added automatically based on domain configuration
- Reduces risk of configuration errors
- Makes the compose file more portable

### 3. Python Health Check
**Decision**: Use Python's urllib instead of curl.

**Rationale**:
- No additional dependency (curl) needed in the image
- Python is already installed in the container
- Cleaner dependency chain
- More reliable across different base images

### 4. Health Check Start Period
**Decision**: 60-second start period for health check.

**Rationale**:
- Initial model download takes 30-60 seconds on first run
- Voice preprocessing adds additional time
- Prevents false health check failures during startup
- Gives the service adequate time to become ready

### 5. Port Configuration
**Decision**: Expose port 8000 internally only (no host port mapping).

**Rationale**:
- Dokploy's Traefik handles routing to the container
- Avoids port conflicts on the host
- More secure - service not directly accessible from host
- Follows best practices for containerized services

## Resource Profile

### Initial Deployment
- **Time**: 5-10 minutes
- **Disk Used**: ~700MB total
  - Docker image: ~500MB
  - Cache volume: ~200MB
- **Network**: ~250MB downloaded (PyTorch + model weights)

### Runtime
- **Memory**: 500-800MB RAM
- **CPU**: 2 cores (can use more for better performance)
- **Disk**: No additional writes (cache is read-only after initial load)
- **Network**: Only for HuggingFace model downloads on first run

### Subsequent Deployments
- **Time**: 1-2 minutes (cached layers)
- **Disk**: Minimal increase (if any)
- **Network**: None (cache persists)

## Usage Patterns

### Pattern 1: Production with Dokploy (Recommended)
```bash
# Configure in Dokploy UI
# - Git source: your repository
# - Domain: tts.yourdomain.com
# - Deploy via Dokploy interface
```

### Pattern 2: Local Development with Docker Compose
```bash
docker-compose up -d
# Access at http://localhost:8000
```

### Pattern 3: Manual Docker (Without Compose)
```bash
docker build -t pocket-tts .
docker run -p 8000:8000 pocket-tts
```

## Security Considerations

### Current Implementation
- Service runs as root (default in base image)
- No authentication built into the service
- Publicly accessible via domain configuration
- No rate limiting

### Recommendations for Production
1. **Authentication**: Add API key authentication via reverse proxy
2. **Rate Limiting**: Implement rate limiting in Traefik
3. **HTTPS**: Always use Dokploy's SSL/TLS (Let's Encrypt)
4. **Network Isolation**: Consider dedicated networks in Dokploy
5. **Regular Backups**: Enable Volume Backups for cache volume
6. **Monitoring**: Set up alerts for health check failures

## Future Enhancements

Potential improvements for future versions:

1. **Customization Options**
   - Environment variable for default voice
   - Configurable port via environment
   - Model variant selection

2. **Performance**
   - Multi-container setup with load balancing
   - Redis for shared cache (if scaling horizontally)

3. **Observability**
   - Structured logging
   - Metrics endpoint (Prometheus)
   - Distributed tracing

4. **Security**
   - Non-root user in container
   - Built-in API key authentication
   - Request rate limiting in application

## Support and Maintenance

### File Maintenance
- `docker-compose.yml`: Update when service configuration changes
- `.dockerignore`: Update when adding new non-essential files
- `.env.example`: Update when adding new environment variables
- `DEPLOYMENT.md`: Update when deployment process changes
- `DOCKER_QUICKSTART.md`: Update when adding quick commands
- `DEPLOYMENT_CHECKLIST.md`: Update when deployment steps change

### Documentation Maintenance
- Keep README.md Docker section in sync with deployment docs
- Update AGENTS.md if Docker patterns change
- Document any breaking changes in deployment process

## Quick Verification

To verify the setup is correct:

```bash
# Check files exist
ls -la docker-compose.yml .dockerignore .env.example
ls -la DEPLOYMENT.md DOCKER_QUICKSTART.md DEPLOYMENT_CHECKLIST.md

# Validate docker-compose.yml
docker-compose config

# Test build locally (optional)
docker-compose build

# Test run locally (optional)
docker-compose up
```

## References

- **Dokploy Documentation**: https://docs.dokploy.com
- **Docker Compose Docs**: https://docs.docker.com/compose
- **Pocket TTS Repository**: https://github.com/kyutai-labs/pocket-tts
- **HuggingFace Model**: https://huggingface.co/kyutai/pocket-tts
