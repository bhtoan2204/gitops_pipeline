import pytest
from app import app


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    with app.test_client() as client:
        yield client


def test_hello_endpoint(client):
    """Test the hello endpoint returns correct response."""
    response = client.get("/")
    assert response.status_code == 200
    assert b"Hello, World!" in response.data


def test_hello_endpoint_content_type(client):
    """Test the hello endpoint returns text/html content type."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.content_type == "text/html; charset=utf-8"


def test_404_on_invalid_route(client):
    """Test that invalid routes return 404."""
    response = client.get("/invalid-route")
    assert response.status_code == 404
