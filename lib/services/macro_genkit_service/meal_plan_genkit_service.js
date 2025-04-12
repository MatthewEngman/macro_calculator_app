require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GenKit } = require('genkit');
const { enableFirebaseTelemetry } = require('@genkit-ai/firebase');

// Enable Firebase telemetry for GenKit
enableFirebaseTelemetry();

const app = express();
app.use(cors());
app.use(express.json());

// Initialize GenKit with your API key
const genkit = new GenKit({
  apiKey: process.env.GEMINI_API_KEY,
  defaultProvider: 'gemini'  // Use Gemini as the default provider
});

// Root endpoint for health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'GenKit meal plan service is running' });
});

app.post('/generate-meal-plan', async (req, res) => {
  try {
    const { diet, goal, macros, ingredients } = req.body;
    
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

    console.log('Generating meal plan with prompt:', prompt);

    // Generate content using GenKit with Gemini
    const response = await genkit.generate({
      provider: 'gemini',
      model: 'gemini-pro',
      prompt,
      responseFormat: { type: 'text' }
    });
    
    console.log('Received response from GenKit');
    res.json({ response: response.text });
  } catch (error) {
    console.error('Error generating meal plan:', error);
    res.status(500).json({ error: 'Failed to generate meal plan', details: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`GenKit meal plan service running on port ${PORT}`);
});