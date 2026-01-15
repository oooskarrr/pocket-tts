# Dokploy Docker Compose Fix - Summary

## Problem

The Pocket TTS app was deploying "successfully" in Dokploy but was not accessible, and logs showed **NO activity whatsoever** (not even health checks). The root cause was that the application binds to `localhost` (127.0.0.1) by default, which is not accessible from outside the container to Dokploy's reverse proxy (Traefik).

## Solution Applied

**Simple and Clean**: Pass `--host 0.0.0.0` flag to the `pocket-tts serve` command, making the service bind to all network interfaces instead of just localhost.

## Changes Made

### 1. docker-compose.yml

**Key Changes:**
- ✅ Port remains `8000` (standard TTS port)
- ✅ Added `dokploy-network` for Dokploy integration
- ✅ Overridden default `command` to add `--host 0.0.0.0` flag:
  ```yaml
  command: ["uv", "run", "pocket-tts", "serve", "--host", "0.0.0.0"]
  ```
- ✅ Kept healthcheck pointing to `localhost:8000` (checks the actual app)
- ✅ Named volumes for HuggingFace cache persistence

**How It Works:**
```
Dokploy/Traefik → 0.0.0.0:8000 (pocket-tts directly accessible)
```

### 2. DEPLOYMENT.md

**Enhancements:**
- ✅ Added "Technical Details" section explaining the network binding solution
- ✅ Added troubleshooting section for "Service Deploys But Not Accessible / No Logs"
- ✅ Clarified that the service now binds to 0.0.0.0:8000
- ✅ Added verification steps to check proper binding

### 3. README.md

**Updates:**
- ✅ Updated Docker usage examples to show `--host 0.0.0.0` flag
- ✅ Clarified that docker-compose.yml binds to 0.0.0.0:8000

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
   - **Important:** Ensure domain points to port 8000
5. **Deploy** → Click Deploy button

### Expected Deployment Logs:

```
INFO:     Started server process [XX]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

**Key indicator:** The host should show `0.0.0.0` not `localhost` or `127.0.0.1`.

## Verification Steps

After deployment, verify the fix is working:

1. **Check Logs** → Should see `Uvicorn running on http://0.0.0.0:8000`
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

1. ✅ **Add `--host 0.0.0.0` flag** - Clean, simple, uses built-in CLI option (CHOSEN)
2. ❌ **Environment variables** - Typer CLI doesn't auto-read env vars for options
3. ❌ **socat forwarding** - Overly complex, requires installing extra packages, harder to debug

### Benefits:

- ✅ Simple and straightforward - just one flag
- ✅ Uses the app's built-in CLI option (documented feature)
- ✅ No additional dependencies or packages needed
- ✅ Easy to debug - logs clearly show which interface is bound
- ✅ Standard Docker practice for server applications
- ✅ Health checks still monitor the actual app directly

## Technical Notes

- **Port 8000** is where pocket-tts runs (bound to 0.0.0.0 - all interfaces)
- **dokploy-network** is external (created by Dokploy)
- **Health checks** still target `localhost:8000` (faster than external interface)
- **Command override** replaces the default Dockerfile CMD

## Troubleshooting

If you still encounter issues:

1. **Check the logs** - Verify you see `http://0.0.0.0:8000` not `http://localhost:8000`
2. **Verify network** - Ensure `dokploy-network` exists: `docker network ls`
3. **Check DNS** - Ensure domain A record points to your server IP
4. **Verify Traefik** - Check Traefik routing configuration in Dokploy UI
5. **Check port** - Ensure Dokploy domain is configured for port 8000

## Support

For more details, see:
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Full deployment guide
- [README.md](./README.md) - Project documentation
- [Dokploy Documentation](https://docs.dokploy.com) - Dokploy-specific help
