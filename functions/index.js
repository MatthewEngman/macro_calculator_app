const { GenKit } = require('genkit');
const cors = require('cors')({ origin: true });

// Add a simple health check endpoint
exports.healthCheck = (req, res) => {
  return cors(req, res, () => {
    console.log('Health check endpoint called');
    res.status(200).json({ status: 'ok', message: 'Meal plan service is up and running' });
  });
};

// Create the meal plan generation function
exports.generateMealPlan = (req, res) => {
  console.log('generateMealPlan function called');
  
  // Log request headers for debugging CORS issues
  console.log('Request headers:', JSON.stringify(req.headers));
  
  return cors(req, res, async () => {
    console.log('Inside CORS handler');
    
    try {
      // Only allow POST requests
      if (req.method !== 'POST') {
        console.log('Method not allowed:', req.method);
        res.status(405).send('Method Not Allowed');
        return;
      }

      console.log('Request body:', JSON.stringify(req.body));
      
      // Check if API key is available
      if (!process.env.GEMINI_API_KEY) {
        console.error('Gemini API key not found in environment variables');
        res.status(500).json({ error: 'API key configuration error' });
        return;
      }

      // Initialize GenKit with your API key from environment variables
      const genkit = new GenKit({
        apiKey: process.env.GEMINI_API_KEY,
      });

      // Validate request body
      if (!req.body || !req.body.diet || !req.body.goal || !req.body.macros || !req.body.ingredients) {
        console.error('Invalid request body:', JSON.stringify(req.body));
        res.status(400).json({ error: 'Invalid request. Required fields: diet, goal, macros, ingredients' });
        return;
      }

      const { diet, goal, macros, ingredients } = req.body;
      
      // Validate macros object
      if (!macros.calories || !macros.protein || !macros.carbs || !macros.fat) {
        console.error('Invalid macros object:', JSON.stringify(macros));
        res.status(400).json({ error: 'Invalid macros. Required fields: calories, protein, carbs, fat' });
        return;
      }
      
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
      // Return a more detailed error message
      res.status(500).json({ 
        error: 'Failed to generate meal plan', 
        details: error.message,
        stack: error.stack
      });
    }
  });
};