# --- Stage 1: Build & Dependencies ---
FROM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11-slim AS runner

WORKDIR /app

# Create non-root system user for container security
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /bin/bash -m appuser

# Copy installed site-packages from builder stage
COPY --from=builder /install /usr/local

# Copy application source code with proper ownership
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8000

# Container Liveness & Readiness Healthcheck Probe
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Launch production Uvicorn server with workers
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
