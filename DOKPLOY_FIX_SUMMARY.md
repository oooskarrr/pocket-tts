# Dokploy Docker Compose Fix - Summary

## Problem

The Pocket TTS app was deploying "successfully" in Dokploy but was not accessible, and logs showed **NO activity whatsoever** (not even health checks). The root cause was that the application binds to `localhost` (127.0.0.1) by default, which is not accessible from outside the container to Dokploy's reverse proxy (Traefik).

## Solution Applied

Implemented a `socat`-based network forwarding solution that acts as a bridge between the public interface and the localhost-bound application.

## Changes Made

### 1. docker-compose.yml

**Key Changes:**
- ✅ Changed exposed port from `8000` to `8080` (socat listen port)
- ✅ Added `dokploy-network` for Dokploy integration
- ✅ Added custom `command` that:
  1. Installs `socat` package
  2. Starts socat in background to forward `0.0.0.0:8080` → `localhost:8000`
  3. Starts the pocket-tts server on `localhost:8000`
- ✅ Kept healthcheck pointing to `localhost:8000` (correct - checks the actual app)
- ✅ Named volumes for HuggingFace cache persistence

**How It Works:**
```
Dokploy/Traefik → 0.0.0.0:8080 (socat) → 127.0.0.1:8000 (pocket-tts)
```

### 2. DEPLOYMENT.md

**Enhancements:**
- ✅ Added "Technical Details" section explaining the network binding solution
- ✅ Added troubleshooting section for "Service Deploys But Not Accessible / No Logs"
- ✅ Updated port references from 8000 to 8080
- ✅ Added socat installation step to first deployment notes

## Deployment Instructions

### In Dokploy UI:

1. **Create Project** → e.g., "pocket-tts"
2. **Add Service** → Type: "Compose"
3. **Configure Source:**
   - Repository: Your pocket-tts repo
   - Branch: `fix-dokploy-docker-compose-socat-forward` (this branch!)
   - Compose Path: `./docker-compose.yml`
4. **Add Domain** (in Domains tab):
   - Enter your domain (e.g., `tts.yourdomain.com`)
   - Dokploy auto-configures Traefik labels
   - **Important:** Ensure domain points to port 8080
5. **Deploy** → Click Deploy button

### Expected First Deployment Logs:

```
Setting up socat...
Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
...
Selecting previously unselected package socat.
Unpacking socat...
Setting up socat...
...
INFO:     Started server process [XX]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000
```

## Verification Steps

After deployment, verify the fix is working:

1. **Check Logs** → Should see socat installation and uvicorn startup
2. **Test Health Endpoint:**
   ```bash
   curl https://your-domain.com/health
   # Expected: {"status":"healthy"}
   ```
3. **Test TTS Endpoint:**
   ```bash
   curl -X POST https://your-domain.com/tts \
     -F "text=Hello world" \
     -F "voice_url=alba" \
     --output test.wav
   ```

## Why This Solution?

### Alternative Approaches Considered:

1. ❌ **Add `--host 0.0.0.0` flag** - Requires modifying application code or Dockerfile CMD
2. ❌ **Environment variables** - Typer CLI doesn't auto-read env vars for options
3. ✅ **socat forwarding** - Works with ANY localhost-bound application, no code changes needed

### Benefits:

- ✅ No application code changes required
- ✅ Works with the existing Docker image
- ✅ Standard solution for "stubborn" apps that bind to localhost
- ✅ Minimal overhead (socat is very lightweight)
- ✅ Health checks still monitor the actual app (not socat)

## Technical Notes

- **Port 8080** is where socat listens (public interface)
- **Port 8000** is where pocket-tts runs (localhost only)
- **socat** runs in background with `fork` mode for concurrent connections
- **dokploy-network** is external (created by Dokploy)
- **Health checks** still target `localhost:8000` (the actual app)

## Support

If you still encounter issues:

1. Check Dokploy logs for socat installation errors
2. Verify `dokploy-network` exists: `docker network ls`
3. Ensure domain DNS A record points to your server
4. Check Traefik routing configuration in Dokploy

For more details, see [DEPLOYMENT.md](./DEPLOYMENT.md).
