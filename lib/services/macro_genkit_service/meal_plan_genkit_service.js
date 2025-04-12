require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(cors());
app.use(express.json());

console.log('Starting meal plan service with AI generation...');
console.log('Environment variables loaded');
console.log('PORT environment variable:', process.env.PORT);
console.log('GEMINI_API_KEY exists:', !!process.env.GEMINI_API_KEY);

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

app.get('/', (req, res) => {
  console.log('Health check endpoint called');
  res.json({ status: 'ok', message: 'Meal plan service is running' });
});

app.post('/generate-meal-plan', async (req, res) => {
  try {
    console.log('Generate meal plan endpoint called');
    const { diet, goal, macros, ingredients } = req.body;
    
    console.log('Request data:', { diet, goal, macros, ingredients });
    
    const prompt = `
      Create a daily meal plan for someone with the following requirements:
      - Diet type: ${diet}
      - Goal: ${goal}
      - Calories: ${macros.calories} kcal
      - Protein: ${macros.protein}g
      - Carbohydrates: ${macros.carbs}g
      - Fat: ${macros.fat}g
      
      Preferred ingredients: ${ingredients.join(', ') || 'No specific preferences'}
      
      Please provide a detailed meal plan with breakfast, lunch, dinner, and snacks.
      Include specific foods, portion sizes, and preparation methods.
      Ensure the total macronutrients match the requirements.
    `;

    console.log('Generating meal plan with prompt...');
    
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });
    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();
    
    console.log('Received response from Gemini');
    res.json({ response: text });
  } catch (error) {
    console.error('Error generating meal plan:', error);
    
    console.log('Falling back to mock meal plan');
    const { diet, goal } = req.body;
    
    res.json({ 
      response: `This is a fallback meal plan for ${diet} diet with ${goal} goal.
      
      Breakfast:
      - Oatmeal with berries
      - Greek yogurt
      
      Lunch:
      - Grilled chicken salad
      - Whole grain bread
      
      Dinner:
      - Baked salmon
      - Steamed vegetables
      - Brown rice
      
      Snacks:
      - Apple with almond butter
      - Protein shake`
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Meal plan service running on port ${PORT}`);
});