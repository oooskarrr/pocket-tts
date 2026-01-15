# FINAL FIX - Health Check Issue Resolved

## The Real Problem (Finally Found!)

The previous fix using `--host 0.0.0.0` **WAS WORKING** - the logs showed:
```
INFO: Uvicorn running on http://0.0.0.0:8000
```

**BUT** the container was marked as **"Unhealthy"** which prevented Traefik from routing traffic to it!

## Root Cause

The health check was failing with this error:
```
OCI runtime exec failed: exec failed: unable to start container process: 
exec: "python": executable file not found in $PATH
```

The health check command was:
```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
```

**Why it failed**: In the uv-based container, `python` isn't directly available in `$PATH` - it's managed by the `uv` tool. The health check couldn't find the `python` executable.

## The Fix

### 1. Updated Dockerfile
Added `curl` installation for health checks:
```dockerfile
# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```

### 2. Updated docker-compose.yml
Changed health check to use `curl` instead of `python`:
```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

## Why This Works

1. **`curl` is available in PATH**: Unlike `python`, `curl` is a standard system utility
2. **Simpler and faster**: No need to start Python interpreter just to check HTTP endpoint
3. **Standard practice**: Most Docker health checks use curl/wget for HTTP services
4. **Traefik compatible**: Once the container is "healthy", Traefik will route traffic to it

## Complete Summary of All Fixes

### Fix #1: Network Binding (Already Working)
✅ Added `--host 0.0.0.0` to the serve command
✅ This made the service accessible from outside the container

### Fix #2: Health Check (NEW - This Was Missing!)
✅ Installed `curl` in the Docker image
✅ Changed health check to use `curl` instead of `python`
✅ This allows the container to pass health checks and be marked "healthy"

## Expected Behavior After Deployment

### 1. Container Logs
```
INFO:     Started server process [XX]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### 2. Container Status
After 60 seconds (the `start_period`), run:
```bash
docker ps
```

You should see:
```
CONTAINER ID   IMAGE                          STATUS
f716c88f84bb   tts-pocket-d98pbh-pocket-tts   Up 2 minutes (healthy)
                                               ^^^^^^^^^^^^^^^^^^^^
                                               Should show "(healthy)" not "(unhealthy)"
```

### 3. Health Check Status
```bash
docker inspect <container-id> | grep -A 10 Health
```

Should show:
```json
"Health": {
  "Status": "healthy",
  "FailingStreak": 0,
  "Log": [
    {
      "Start": "2026-01-15T...",
      "End": "2026-01-15T...",
      "ExitCode": 0,
      "Output": "{\"status\":\"healthy\"}\n"
    }
  ]
}
```

### 4. Service Access
Once the container is healthy, you should be able to access:

```bash
# Health endpoint
curl https://tts.omnilocal.de/health
# Response: {"status":"healthy"}

# Web interface
curl https://tts.omnilocal.de/
# Response: HTML content

# TTS API
curl -X POST https://tts.omnilocal.de/tts \
  -F "text=Hello world" \
  -F "voice_url=alba" \
  --output test.wav
# Should download a WAV file
```

## Timeline of Issues & Fixes

1. **Original Problem**: App deployed but got 404 errors, no logs
   - **Cause**: App was binding to localhost (127.0.0.1)
   - **Fix**: Added `--host 0.0.0.0` flag ✅

2. **Second Problem**: App logs showed correct binding (0.0.0.0:8000) but still 404 errors
   - **Cause**: Container was "unhealthy", Traefik wouldn't route to it
   - **Diagnosis**: Health check was failing (python not in PATH)
   - **Fix**: Install curl + use curl for health checks ✅

## Why Traefik Requires Healthy Containers

Traefik (Dokploy's reverse proxy) checks container health before routing traffic:
- ✅ **Healthy container** → Traffic is routed normally
- ❌ **Unhealthy container** → Traffic is NOT routed (returns 404)

This is a safety feature to prevent routing traffic to broken services.

## Files Changed

1. **Dockerfile**
   - Added curl installation

2. **docker-compose.yml**
   - Changed health check from `python` to `curl`
   - Kept `--host 0.0.0.0` flag (already working)

3. **DEPLOYMENT.md**
   - Updated troubleshooting section
   - Added health check verification steps

## Next Steps

1. **Push changes** to your git repository
2. **Redeploy** in Dokploy (it will rebuild the image with curl)
3. **Wait 60 seconds** after deployment starts (health check start_period)
4. **Verify** container shows as "(healthy)" in Dokploy UI
5. **Test** the service at your domain

## If It Still Doesn't Work

Check these in order:

1. **Container status**: `docker ps` - should show "(healthy)"
2. **Health check logs**: `docker inspect <container-id> | grep -A 20 Health`
3. **Traefik logs**: Check if Traefik is seeing the healthy container
4. **DNS**: Verify domain points to your server IP
5. **Firewall**: Ensure ports 80 and 443 are open

The health check is the critical piece - if the container is healthy, Traefik will route traffic to it!
