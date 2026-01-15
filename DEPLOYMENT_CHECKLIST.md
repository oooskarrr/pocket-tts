# Docker Compose Deployment Checklist

Use this checklist when deploying Pocket TTS with Docker Compose and Dokploy.

## Pre-Deployment

- [ ] Repository contains all required files:
  - [ ] `docker-compose.yml`
  - [ ] `Dockerfile`
  - [ ] `.dockerignore`
- [ ] Repository is pushed to Git (GitHub, GitLab, Gitea, or Bitbucket)
- [ ] Dokploy server is accessible and running
- [ ] Docker is installed on the Dokploy server

## Dokploy Setup

- [ ] Created a new Dokploy project
- [ ] Created a new "Compose" service in the project
- [ ] Selected "Docker Compose" as Compose Type
- [ ] Configured Git source:
  - [ ] Selected correct Git provider
  - [ ] Selected the correct repository
  - [ ] Selected the correct branch
- [ ] Set Compose Path to `./docker-compose.yml`

## Domain Configuration (Recommended)

- [ ] Went to the "Domains" tab in Dokploy
- [ ] Added a domain (e.g., `tts.yourdomain.com`)
- [ ] Dokploy shows domain as active

## Environment Variables (Optional)

- [ ] Reviewed `.env.example` for available options
- [ ] Added any needed environment variables in Dokploy's Environment tab

## Deployment

- [ ] Clicked "Deploy" button
- [ ] Waited for initial deployment to complete (5-10 minutes expected)
- [ ] Checked that deployment status shows as "Success"

## Post-Deployment Verification

- [ ] Service shows as "Running" in Dokploy dashboard
- [ ] Health check passes (green indicator)
- [ ] Can access the web interface via configured domain
- [ ] Can generate speech using the web interface
- [ ] Can access health endpoint: `https://your-domain.com/health`
- [ ] Can access API endpoint via curl:
  ```bash
  curl -X POST https://your-domain.com/tts \
    -F "text=Test" \
    -F "voice_url=alba" \
    --output test.wav
  ```

## Monitoring & Maintenance

- [ ] Verified logs are accessible in Dokploy "Logs" tab
- [ ] Checked resource usage in "Monitoring" tab:
  - [ ] CPU usage is normal (< 50%)
  - [ ] Memory usage is normal (< 800MB)
- [ ] Confirmed cache volume exists and has data:
  ```bash
  docker volume ls | grep pocket-tts-cache
  ```

## Optional: Auto-Deployment

- [ ] Copied webhook URL from "Deployments" tab
- [ ] Added webhook to Git repository
- [ ] Tested webhook by pushing a small change

## Troubleshooting (If needed)

### Slow First Deployment
- [ ] Confirmed internet connectivity for model downloads
- [ ] Waited at least 10 minutes for initial deployment

### Health Check Failing
- [ ] Checked logs for error messages
- [ ] Verified port 8000 is not already in use
- [ ] Confirmed sufficient RAM available (min 1GB free)

### Cache Not Persisting
- [ ] Verified named volume exists: `docker volume ls`
- [ ] Checked that `pocket-tts-cache` volume is mounted correctly

### Cannot Access Service
- [ ] Confirmed DNS A record points to correct IP
- [ ] Waited 10-30 seconds for Traefik to configure
- [ ] Checked Traefik logs in Dokploy

## Additional Resources

- **Full Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Quick Reference**: [DOCKER_QUICKSTART.md](./DOCKER_QUICKSTART.md)
- **Dokploy Docs**: https://docs.dokploy.com
- **Pocket TTS Issues**: https://github.com/kyutai-labs/pocket-tts/issues
