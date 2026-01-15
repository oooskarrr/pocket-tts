# Change Summary - Simplified Dokploy Fix

## What Changed

### Previous Approach (Complex - Didn't Work)
- Attempted to use `socat` to forward traffic from 0.0.0.0:8080 → localhost:8000
- Required installing socat package at container startup
- Changed exposed port from 8000 to 8080
- Complex shell command in docker-compose.yml
- **Problem:** The socat installation wasn't executing properly, causing the fix not to work

### New Approach (Simple - Should Work)
- Directly pass `--host 0.0.0.0` flag to the `pocket-tts serve` command
- No additional packages needed
- Keep port 8000 (standard)
- Clean command array in docker-compose.yml
- Uses the app's built-in CLI feature

## Key File Changes

### docker-compose.yml
```yaml
# OLD (socat approach):
ports:
  - 8080
command: >
  /bin/sh -c "
  apt-get update && apt-get install -y socat &&
  (socat TCP-LISTEN:8080,fork,bind=0.0.0.0 TCP:127.0.0.1:8000 &) &&
  exec uv run pocket-tts serve
  "

# NEW (direct flag approach):
ports:
  - 8000
command: ["uv", "run", "pocket-tts", "serve", "--host", "0.0.0.0"]
```

## What To Look For After Deploying

### In Logs (Critical!)
**OLD logs showed:**
```
INFO:     Uvicorn running on http://localhost:8000
```

**NEW logs should show:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

The key difference is `0.0.0.0` vs `localhost` - this confirms the service is accessible from outside the container.

### In Dokploy Configuration
1. **Domain configuration** should point to port **8000** (not 8080)
2. **Network** should be `dokploy-network` (already configured)
3. **Traefik labels** will be auto-added by Dokploy (see preview-compose)

## Why This Should Work

1. **Uses documented CLI feature**: The `--host` flag is part of the official CLI interface
2. **Simpler = fewer failure points**: No external packages, no complex shell commands
3. **Standard practice**: This is how most Python web apps are deployed in Docker
4. **Easy to verify**: The logs will clearly show which interface is bound
5. **No timing issues**: No need to wait for package installation before app starts

## Testing After Deployment

Once deployed, test with:

```bash
# 1. Check logs show correct binding
# Look for: "Uvicorn running on http://0.0.0.0:8000"

# 2. Test health endpoint
curl https://tts.mydomain.com/health
# Should return: {"status":"healthy"}

# 3. Test TTS generation
curl -X POST https://tts.mydomain.com/tts \
  -F "text=Hello, this is a test." \
  -F "voice_url=alba" \
  --output test.wav

# 4. Verify the WAV file
file test.wav
# Should show: RIFF (little-endian) data, WAVE audio
```

## If It Still Doesn't Work

Check these things:

1. **Logs show localhost not 0.0.0.0**: The command override isn't being applied
   - Verify you're deploying from the correct branch
   - Check docker-compose.yml in Dokploy shows the command array

2. **404 errors**: Traefik can't reach the service
   - Verify dokploy-network is connected
   - Check Traefik labels in preview-compose
   - Ensure domain DNS points to server IP

3. **No logs at all**: Container might be failing to start
   - Check container status in Dokploy
   - Look for startup errors in logs
   - Verify the image built successfully

4. **Health checks failing**: The service isn't starting properly
   - Check for model download issues (needs ~200MB)
   - Verify sufficient memory (needs ~600MB RAM)
   - Check for Python/dependency errors in logs
