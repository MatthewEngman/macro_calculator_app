from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests

app = FastAPI()

class MealPlanRequest(BaseModel):
    diet: str
    goal: str
    macros: dict
    ingredients: list

@app.post("/generate-meal-plan/")
async def generate_meal_plan(request: MealPlanRequest):
    prompt = f"Generate a {request.diet} meal plan for {request.goal} goal.\n"
    prompt += f"Calories: {request.macros['calories']} kcal\n"
    prompt += f"Protein: {request.macros['protein']}g\n"
    prompt += f"Carbs: {request.macros['carbs']}g\n"
    prompt += f"Fat: {request.macros['fat']}g\n"
    prompt += f"Available ingredients: {', '.join(request.ingredients)}.\n"
    prompt += "Include ingredients, macros, and full step-by-step recipe."

    # Call local Ollama (Gemma) instance
    response = requests.post("http://localhost:11434/api/generate", json={
        "model": "gemma",
        "prompt": prompt,
        "stream": False
    })

    if response.status_code == 200:
        return response.json()
    else:
        raise HTTPException(status_code=response.status_code, detail="Model error")
