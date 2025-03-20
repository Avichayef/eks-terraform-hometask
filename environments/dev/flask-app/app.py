# Flask App
# two endpoints:
# - /: welcome message
# - /health: health check status

import os
from flask import Flask, jsonify

from flask import Flask, jsonify

app = Flask(__name__)

# Get configuration from environment variables
FLASK_HOST = os.getenv('FLASK_HOST', '0.0.0.0')
FLASK_PORT = int(os.getenv('FLASK_PORT', 5000))

@app.route('/')
def home():
    return "Welcome to the Kubernetes DevOps Challenge!"

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(host=FLASK_HOST, port=FLASK_PORT)
