FROM ghcr.io/astral-sh/uv:debian

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./pyproject.toml .
COPY ./uv.lock .
COPY ./README.md .
COPY ./.python-version .
COPY ./pocket_tts ./pocket_tts

RUN uv run pocket-tts serve --help && \
    rm -rf /root/.cache/uv && \
    uv run pocket-tts serve --help

CMD ["uv", "run", "pocket-tts", "serve"]