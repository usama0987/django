FROM python:3.9-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH "/app:${PYTHONPATH}"
ENV DJANGO_SETTINGS_MODULE "django_api.settings"

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y gcc && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Change working directory to where manage.py is located
WORKDIR /app/django_api

# Final command
CMD ["sh", "-c", "python manage.py migrate && gunicorn --bind 0.0.0.0:8000 --timeout 120 --workers 2 django_api.wsgi:application"]
