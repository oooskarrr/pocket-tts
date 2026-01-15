# Docker Compose Setup - What Was Added

This document summarizes the Docker Compose files added to support Dokploy deployment.

## New Files

1. **docker-compose.yml**
   - Main Docker Compose configuration
   - Configured for Dokploy deployment
   - Includes named volume for cache persistence

2. **.dockerignore**
   - Excludes unnecessary files from Docker builds
   - Reduces image size and build time

3. **.env.example**
   - Template for environment variables
   - Documents available options

4. **DEPLOYMENT.md**
   - Complete Dokploy deployment guide
   - Step-by-step instructions
   - Troubleshooting section

5. **DOCKER_QUICKSTART.md**
   - Quick reference for common Docker commands
   - Troubleshooting quick guide

6. **DEPLOYMENT_CHECKLIST.md**
   - Step-by-step deployment checklist
   - Verification steps

7. **DOCKER_SETUP_SUMMARY.md**
   - Technical documentation of the setup
   - Architecture diagram
   - Design decisions explained

## Modified Files

1. **README.md**
   - Added "Deployment with Docker" section
   - References the new DEPLOYMENT.md

## Next Steps

### Deploy with Dokploy

1. **Push to Git**
   ```bash
   git add .
   git commit -m "Add Docker Compose setup for Dokploy"
   git push
   ```

2. **In Dokploy**
   - Create a new project
   - Create a "Compose" service
   - Select Docker Compose type
   - Choose your Git repository
   - Set compose path to `./docker-compose.yml`

3. **Configure Domain** (Optional but recommended)
   - Go to Domains tab
   - Add your domain (e.g., `tts.yourdomain.com`)
   - Dokploy handles SSL/TLS automatically

4. **Deploy**
   - Click "Deploy"
   - Wait 5-10 minutes for first deployment
   - Access your service at the configured domain

### Quick Local Test

To test locally before deploying:

```bash
# Build and run
docker-compose up -d

# Check logs
docker-compose logs -f

# Test the API
curl -X POST http://localhost:8000/tts \
  -F "text=Hello world" \
  -F "voice_url=alba" \
  --output test.wav

# Stop
docker-compose down
```

## Important Notes

- **First Deployment**: Takes 5-10 minutes (downloads PyTorch and models)
- **Cache Persistence**: Models are cached in a named volume - persists across deployments
- **No Traefik Labels Needed**: Dokploy's domain management handles routing automatically
- **Health Check**: Service health is monitored automatically
- **Port**: Service runs on port 8000 (internal to Docker network)

## Support

- For Dokploy-specific issues: https://docs.dokploy.com
- For Pocket TTS issues: https://github.com/kyutai-labs/pocket-tts/issues
- See DEPLOYMENT.md for detailed troubleshooting
