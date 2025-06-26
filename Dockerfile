# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY API/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the API code
COPY API/ .

# Set environment variables
ENV TIMEZONE=America/New_York
ENV PYTHONPATH=/app

# Expose port
EXPOSE 4463

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4463/f1/next_race/ || exit 1

# Run the application
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4463"]
