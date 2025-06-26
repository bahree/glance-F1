FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && rm -rf /root/.cache /var/lib/apt/lists/*

COPY . .

# Set default environment variables
ENV TRACK_COLOUR="#e10600"
ENV TIMEZONE="America/Los_Angeles"

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4463"]

