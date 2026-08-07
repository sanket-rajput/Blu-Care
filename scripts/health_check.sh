#!/usr/bin/env bash
# ==============================================================================
# BluCare+ Production Health Check & Endpoint Verification Script
# ==============================================================================

set -euo pipefail

BACKEND_URL="${BACKEND_URL:-http://localhost:8000}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:80}"

echo "🔍 Running BluCare+ Deep Health Check..."

# 1. Check Backend Liveness Probe
echo -n "Checking Backend Liveness (/health)... "
LIVENESS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/health" || echo "000")
if [ "$LIVENESS_CODE" -eq 200 ]; then
    echo "✅ [200 OK]"
else
    echo "❌ [FAILED - HTTP ${LIVENESS_CODE}]"
    exit 1
fi

# 2. Check Backend Readiness Probe (Qdrant & Redis)
echo -n "Checking Backend Readiness (/health/ready)... "
READINESS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/health/ready" || echo "000")
if [ "$READINESS_CODE" -eq 200 ]; then
    echo "✅ [200 OK]"
else
    echo "❌ [FAILED - HTTP ${READINESS_CODE}]"
    exit 1
fi

# 3. Check API v1 Router Hospital Endpoint
echo -n "Checking API v1 Hospital Lookup (/api/v1/hospitals/nearby)... "
HOSPITAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/api/v1/hospitals/nearby?lat=18.52&lng=73.85" || echo "000")
if [ "$HOSPITAL_CODE" -eq 200 ]; then
    echo "✅ [200 OK]"
else
    echo "❌ [FAILED - HTTP ${HOSPITAL_CODE}]"
    exit 1
fi

# 4. Check Frontend Static SPA Server
echo -n "Checking Frontend Web Application (Port 80)... "
FRONTEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}/" || echo "000")
if [ "$FRONTEND_CODE" -eq 200 ]; then
    echo "✅ [200 OK]"
else
    echo "❌ [FAILED - HTTP ${FRONTEND_CODE}]"
    exit 1
fi

echo "🎉 All system health probes passed cleanly!"
exit 0
