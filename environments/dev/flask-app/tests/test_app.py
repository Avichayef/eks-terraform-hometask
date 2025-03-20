# Test for Flask App on endpoints:
# / (home page)
# /health (health check endpoint)

import pytest
from app import app

@pytest.fixture
def client():
    """
    Test client fixture for Flask application.
    
    Returns:
        FlaskClient: A test client for the Flask application
    """
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """
    Test the home page endpoint (/).
    
    Verifies that:
    - The endpoint returns the expected welcome message
    """
    rv = client.get('/')
    assert b"Welcome to the Kubernetes DevOps Challenge!" in rv.data

def test_health_check(client):
    """
    Test the health check endpoint (/health).
    
    Verifies that:
    - The endpoint returns a 200 status code
    - The response contains the expected JSON structure
    """
    rv = client.get('/health')
    assert rv.status_code == 200
    assert rv.json == {"status": "ok"}
