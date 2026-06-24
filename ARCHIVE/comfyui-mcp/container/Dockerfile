# comfyui-mcp server image. The ComfyUI image is built/pulled separately (see compose.yml `comfyui` service);
# this image is the thin, secured MCP server that fronts it. Built by FOUNDRY from server/ — see ../EARS.md.
FROM python:3.12-slim AS base

# Non-root: the server holds an auth token and proxies a backend; it never needs root.
RUN useradd --create-home --uid 10001 mcp
WORKDIR /app

# Dependencies first (layer cache). server/ is foundry-built; pyproject pins exact versions (sentinel
# /dependency-audit gate).
COPY server/pyproject.toml server/uv.lock* /app/
RUN pip install --no-cache-dir uv && uv sync --frozen --no-dev || pip install --no-cache-dir .

COPY server/ /app/

USER mcp
EXPOSE 8765
# The server reads COMFYUI_INTERNAL_URL, MODEL_ALLOWLIST_DIR, MCP_AUTH_TOKEN from the environment (compose.yml).
# No secrets baked into the image (sentinel /secret-scan gate).
CMD ["python", "-m", "comfyui_mcp.server"]
