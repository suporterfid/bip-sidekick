# Replace with a maintained Google Workspace MCP image, or build a thin server here.
FROM python:3.12-slim
RUN useradd -u 10001 -m app
WORKDIR /app
# COPY requirements.txt . && RUN pip install --no-cache-dir -r requirements.txt
USER 10001
CMD ["python","-c","print('google-mcp stub — wire a read-only Workspace MCP server on :8081'); import time; time.sleep(10**9)"]
