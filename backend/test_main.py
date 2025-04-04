import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
from main import app

client = TestClient(app)

def test_generate_meal_plan_success():
    test_request = {
        "diet": "vegetarian",
        "goal": "weight loss",
        "macros": {
            "calories": 2000,
            "protein": 100,
            "carbs": 200,
            "fat": 70
        },
        "ingredients": ["tofu", "rice", "vegetables"]
    }
    
    # Mock the Ollama API response
    mock_response = {"response": "Mocked meal plan response"}
    
    with patch('requests.post') as mock_post:
        mock_post.return_value.status_code = 200
        mock_post.return_value.json.return_value = mock_response
        
        response = client.post("/generate-meal-plan/", json=test_request)
        
        assert response.status_code == 200
        assert response.json() == mock_response

def test_generate_meal_plan_model_error():
    test_request = {
        "diet": "vegetarian",
        "goal": "weight loss",
        "macros": {
            "calories": 2000,
            "protein": 100,
            "carbs": 200,
            "fat": 70
        },
        "ingredients": ["tofu", "rice", "vegetables"]
    }
    
    with patch('requests.post') as mock_post:
        mock_post.return_value.status_code = 500
        
        response = client.post("/generate-meal-plan/", json=test_request)
        
        assert response.status_code == 500
        assert "Model error" in response.json()["detail"]

def test_generate_meal_plan_invalid_request():
    invalid_request = {
        "diet": "vegetarian",
        # Missing required fields
    }
    
    response = client.post("/generate-meal-plan/", json=invalid_request)
    assert response.status_code == 422  # Validation error