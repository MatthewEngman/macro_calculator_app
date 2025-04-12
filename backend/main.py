# In your FastAPI backend
import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class MealPlanRequest(BaseModel):
    diet: str
    goal: str
    macros: dict
    ingredients: list

@app.post("/generate-meal-plan/")
async def generate_meal_plan(request: MealPlanRequest):
    try:
        # Forward the request to the Gemini service
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://localhost:3000/generate-meal-plan",  # Or your deployed URL
                json={
                    "diet": request.diet,
                    "goal": request.goal,
                    "macros": request.macros,
                    "ingredients": request.ingredients
                },
                timeout=60.0  # Longer timeout for AI generation
            )
            
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(status_code=response.status_code, detail="Failed to generate meal plan")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")