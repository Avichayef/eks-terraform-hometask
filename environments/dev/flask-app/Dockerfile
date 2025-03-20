FROM python:3.9-slim

# working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY app.py .

# Use ARG for build-time variables
ARG FLASK_PORT=5000
ENV FLASK_PORT=${FLASK_PORT}

EXPOSE ${FLASK_PORT}

CMD ["python", "app.py"]
