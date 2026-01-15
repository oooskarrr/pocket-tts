# Docker Compose Quick Reference

Quick reference for deploying Pocket TTS with Docker Compose.

## Files Overview

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main Docker Compose configuration |
| `Dockerfile` | Container image definition (existing) |
| `.dockerignore` | Files to exclude from Docker build |
| `.env.example` | Environment variable template |
| `DEPLOYMENT.md` | Full Dokploy deployment guide |

## Quick Commands

```bash
# Build and run locally
docker-compose up -d

# View logs
docker-compose logs -f

# Stop service
docker-compose down

# Remove cache volume (WARNING: redownloads all models)
docker-compose down -v
```

## Service Details

### Configuration
- **Image**: Built from Dockerfile using `uv` runtime
- **Port**: 8000 (exposed internally to Dokploy network)
- **Restart Policy**: `unless-stopped`
- **Health Check**: `/health` endpoint every 30s

### Volumes
- `pocket-tts-cache`: Persists `/root/.cache/pocket_tts`
  - Model weights (~200MB)
  - Tokenizer models
  - Preprocessed voice embeddings

### Environment
- `PYTHONUNBUFFERED=1`: Proper log streaming

## Resource Requirements

- **RAM**: 500-800MB minimum
- **CPU**: 2 cores recommended
- **Disk**: 500MB for image + 250MB for cache
- **Network**: Stable internet for initial model download

## First Run

Initial deployment will take 5-10 minutes:
1. Pull base image (~50MB)
2. Install Python dependencies (~400MB)
3. Download model weights (~200MB)
4. Preprocess default voice

Subsequent deployments are much faster due to layer caching.

## Accessing the Service

### Web Interface
- Default: `http://localhost:8000` (local)
- With Dokploy: Use your configured domain

### API Endpoint
```bash
# Generate speech
curl -X POST http://localhost:8000/tts \
  -F "text=Hello world" \
  -F "voice_url=alba" \
  --output output.wav
```

### Health Check
```bash
curl http://localhost:8000/health
# Returns: {"status":"healthy"}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Slow first start | Normal - downloading 200MB of models |
| Cache not persisting | Ensure named volume exists: `docker volume ls` |
| Port already in use | Change port in `docker-compose.yml` |
| Out of memory | Ensure at least 1GB free RAM |
| Healthcheck failing | Check logs: `docker-compose logs` |

## Customization

### Change Default Voice
Edit `Dockerfile` CMD:
```dockerfile
CMD ["uv", "run", "pocket-tts", "serve", "--voice", "marius"]
```

### Change Port
Edit `docker-compose.yml`:
```yaml
ports:
  - 9000
```

### Add Environment Variables
Edit `docker-compose.yml` or use Dokploy's Environment tab.

## Production Deployment

For production use, follow the full guide in **[DEPLOYMENT.md](./DEPLOYMENT.md)** which covers:
- Dokploy setup and configuration
- Domain management and SSL
- Monitoring and logging
- Webhook auto-deployment
- Advanced configuration options

## Support

- **Dokploy**: https://docs.dokploy.com
- **Pocket TTS**: https://github.com/kyutai-labs/pocket-tts/issues
