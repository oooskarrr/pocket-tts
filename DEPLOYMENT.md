# Dokploy Deployment Guide

This guide explains how to deploy Pocket TTS using Dokploy with Docker Compose.

## Prerequisites

- A Dokploy instance running on your server
- A Git repository (GitHub, GitLab, Gitea, or Bitbucket) containing this project
- Docker installed on your Dokploy server

## Quick Start

### 1. Push Your Code to a Git Repository

If you haven't already, push this project to a Git repository that Dokploy can access:

```bash
git add .
git commit -m "Add Docker Compose setup for Dokploy"
git push origin main
```

### 2. Create a Dokploy Project

1. Log in to your Dokploy dashboard
2. Click **"New Project"**
3. Enter a project name (e.g., "pocket-tts")
4. Click **"Create"**

### 3. Create a Docker Compose Service

1. Within your project, click **"New Service"**
2. Select **"Compose"**
3. Configure the following:
   - **Compose Type**: Docker Compose (recommended)
   - **Compose Path**: `./docker-compose.yml`
4. Under **General**:
   - **Source Type**: Git
   - **Git Provider**: Select your provider (GitHub, GitLab, etc.)
   - **Repository**: Select `pocket-tts` (or your repo name)
   - **Branch**: `main` (or your default branch)
5. Click **"Create"**

### 4. Configure Domain (Optional but Recommended)

Dokploy supports native domain management - the easiest way to expose your service:

1. Go to the **Domains** tab of your Pocket TTS service
2. Click **"Add Domain"**
3. Enter your domain (e.g., `tts.yourdomain.com`)
4. Dokploy will automatically:
   - Add Traefik labels to route traffic
   - Configure SSL/TLS certificates via Let's Encrypt
   - Handle all networking configuration

**Note**: No manual Traefik labels in `docker-compose.yml` are needed - Dokploy handles this automatically!

### 5. Deploy

1. Click the **"Deploy"** button
2. Wait for the deployment to complete
   - Initial deployment may take several minutes as it downloads PyTorch and model weights
   - Subsequent deployments will be much faster due to caching
3. Once complete, access your TTS service at your configured domain or via direct IP:port

## Configuration Options

### Environment Variables

You can set environment variables in the **Environment** tab in Dokploy. The `.env.example` file documents available options.

Common environment variables:

```bash
PYTHONUNBUFFERED=1  # Recommended for proper log output
```

### Customizing the Default Voice

To change the default voice used by the server, you can modify the `CMD` in `Dockerfile`:

```dockerfile
CMD ["uv", "run", "pocket-tts", "serve", "--voice", "marius"]
```

Available predefined voices: `alba`, `marius`, `javert`, `jean`, `fantine`, `cosette`, `eponine`, `azelma`

### Persistent Storage

The Docker Compose setup includes a named volume `pocket-tts-cache` that persists:

- Downloaded HuggingFace model weights (~200MB)
- Pre-processed voice prompt embeddings
- Tokenizer models

This cache is preserved across deployments, significantly improving startup times.

## Using the Service

### Web Interface

Once deployed, visit your domain to use the web interface:
- Enter text in the text area
- Select a voice (or upload your own)
- Click "Generate" to create audio

### API Endpoint

The service exposes a REST API at `/tts`:

```bash
curl -X POST https://tts.yourdomain.com/tts \
  -F "text=Hello world, this is a test." \
  -F "voice_url=alba" \
  --output speech.wav
```

### Health Check

A health check endpoint is available at `/health`:

```bash
curl https://tts.yourdomain.com/health
# Returns: {"status":"healthy"}
```

## Monitoring and Logs

### View Logs

In Dokploy:
1. Go to the **Logs** tab of your service
2. Select the `pocket-tts` service
3. View real-time logs for debugging and monitoring

### Monitor Resources

The **Monitoring** tab shows:
- CPU usage
- Memory usage
- Container health status

## Webhooks for Auto-Deployment

To automatically deploy when you push changes:

1. Go to the **Deployments** tab
2. Copy the webhook URL
3. Add it as a webhook in your Git repository settings
4. Every push will trigger a new deployment

## Technical Details

### Network Binding Solution

Pocket TTS by default binds to `localhost` (127.0.0.1) when running the `serve` command. This works fine for local development but prevents Dokploy's reverse proxy (Traefik) from accessing the service.

**Solution**: The `docker-compose.yml` overrides the default command to add `--host 0.0.0.0`:
- The app runs on `0.0.0.0:8000` (accessible from outside the container)
- Dokploy/Traefik connects directly to port 8000
- No additional forwarding tools needed

This happens automatically during container startup - no manual configuration needed!

## Troubleshooting

### Slow First Deployment

The first deployment will take several minutes because:
- It downloads the base Docker image
- Installs all Python dependencies (including PyTorch)
- Downloads model weights from HuggingFace Hub (~200MB)
- Pre-processes the default voice prompt

### Model Downloads Not Persisting

If models are re-downloading on every deployment:
1. Check that the `pocket-tts-cache` volume exists: `docker volume ls`
2. Verify the volume is correctly mounted in the container
3. Check that you're using Docker Compose (not Docker Stack), as Stack doesn't support named volumes the same way

### Out of Memory Errors

If you encounter OOM errors:
1. Ensure your server has at least 1GB of free RAM
2. The app is optimized for CPU and uses ~400-600MB of RAM
3. Check Dokploy's resource limits if configured

### Port Conflicts

If port 8000 is already in use:
1. Modify the `ports` and `command` in `docker-compose.yml`:
   ```yaml
   ports:
     - 9000  # Change to another port
   command: ["uv", "run", "pocket-tts", "serve", "--host", "0.0.0.0", "--port", "9000"]
   ```
2. Update the health check to use the new port
3. Update the Dokploy domain configuration to point to the new port

### Service Deploys But Not Accessible / No Logs

If your deployment shows as "successful" but:
- You cannot access the service through the domain
- Logs show NO activity at all (not even health checks)
- Container appears to be running

**Root Cause**: The app is binding to `localhost` (127.0.0.1) inside the container, which Dokploy's reverse proxy cannot reach.

**Fix Applied**: This repository includes the fix by passing `--host 0.0.0.0` to the serve command in `docker-compose.yml`. Make sure:
1. You're deploying from a branch that includes the `--host 0.0.0.0` flag in the command
2. The `dokploy-network` is properly configured (it should be external)
3. Your domain in Dokploy is configured to point to port 8000

To verify the fix is working, check the logs - you should see:
```
INFO:     Started server process [XX]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

Note the host should show `0.0.0.0` not `localhost` or `127.0.0.1`.

## Advanced Configuration

### Using Docker Stack (Swarm Mode)

If you prefer Docker Stack for swarm deployment:
1. Change **Compose Type** to "Stack"
2. Note that Docker Stack does NOT support `build` - you must:
   - Build the image separately: `docker build -t your-registry/pocket-tts:latest .`
   - Push to a registry: `docker push your-registry/pocket-tts:latest`
   - Update `docker-compose.yml` to use `image:` instead of `build:`
3. Add `--with-registry-auth` flag in Dokploy Advanced settings if using a private registry

### Custom Host for Cache Directory

To use a different cache location, modify the volume mount:

```yaml
volumes:
  - ./custom-cache:/root/.cache/pocket_tts
```

Then ensure the `./custom-cache` directory is properly persisted.

## Support

For issues specific to:
- **Dokploy**: Check [Dokploy Documentation](https://docs.dokploy.com)
- **Pocket TTS**: Visit [GitHub Issues](https://github.com/kyutai-labs/pocket-tts/issues)

## Security Considerations

1. **Domain Exposure**: Only expose your service via HTTPS using Dokploy's domain management
2. **API Access**: Consider adding authentication if deploying publicly
3. **Rate Limiting**: Implement rate limiting if needed to prevent abuse
4. **Voice Cloning**: Be aware that voice cloning capabilities can be misused - review the Prohibited Use section in README.md
