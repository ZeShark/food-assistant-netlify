import { getOpenRouterConfig } from './utils/apiConfig.js';

export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Handle OPTIONS request for CORS
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  let body = req.body;
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (parseError) {
      return res.status(400).json({
        success: false,
        error: 'Invalid JSON in request body'
      });
    }
  }

  try {
    // Destructure with default values to avoid undefined errors
    const { 
      ingredients, 
      dietaryPreferences, 
      mealType, 
      cuisine, 
      model = 'google/gemini-flash-1.5',
      preferredIngredients = [],  // Add default empty array
      dislikedIngredients = []    // Add default empty array
    } = body;

    console.log('=== RECIPE GENERATION REQUEST ===');
    console.log('Ingredients:', ingredients);
    console.log('Model:', model);

    if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'Ingredients are required and must be a non-empty array' 
      });
    }

    const openRouterConfig = getOpenRouterConfig();
    
    // Check if API key is available
    if (!openRouterConfig.apiKey) {
      console.error('OpenRouter API key is missing');
      return res.status(500).json({
        success: false,
        error: 'OpenRouter API key is not configured'
      });
    }

    console.log('OpenRouter config loaded, key length:', openRouterConfig.apiKey?.length);
    
    // Build the prompt
    let prompt = `Create a delicious recipe using these main ingredients: ${ingredients.join(', ')}`;

    // Add optional filters - only if they have values
    if (cuisine && cuisine !== 'Any cuisine') {
      prompt += `\nCuisine style: ${cuisine}`;
    }
    if (mealType && mealType !== 'Time doesn\'t matter') {
      prompt += `\nMeal type: ${mealType}`;
    }
    if (dietaryPreferences) {
      prompt += `\nDietary preferences: ${dietaryPreferences}`;
    }
    if (preferredIngredients && preferredIngredients.length > 0) {
      prompt += `\nPreferred additional ingredients: ${preferredIngredients.join(', ')}`;
    }
    if (dislikedIngredients && dislikedIngredients.length > 0) {
      prompt += `\nIngredients to avoid: ${dislikedIngredients.join(', ')}`;
    }

    prompt += `\n\nReturn ONLY valid JSON in this exact format (no other text, no markdown):\n{
  "title": "Recipe Name",
  "description": "Brief description of the recipe",
  "ingredients": [
    {"name": "ingredient1", "amount": "1 cup"},
    {"name": "ingredient2", "amount": "2 tbsp"}
  ],
  "instructions": [
    "Step 1 instruction",
    "Step 2 instruction"
  ],
  "cookingTime": "30 minutes",
  "difficulty": "Easy"
}`;

    console.log('Sending prompt to OpenRouter...');

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterConfig.apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': openRouterConfig.referer || 'https://food-assistant-netlify.vercel.app',
        'X-Title': openRouterConfig.title || 'Food Assistant'
      },
      body: JSON.stringify({
        model: model,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 1500,
        temperature: 0.7
      })
    });

    console.log('OpenRouter response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      
      let errorMessage = `OpenRouter API error: ${response.status}`;
      if (response.status === 401) {
        errorMessage = 'Invalid API key - check your OpenRouter configuration';
      } else if (response.status === 429) {
        errorMessage = 'Rate limit exceeded - try again later';
      } else if (response.status === 404) {
        errorMessage = 'Model not found - try a different model';
      }
      
      throw new Error(errorMessage);
    }

    const data = await response.json();
    console.log('OpenRouter response received');
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      throw new Error('Invalid response format from OpenRouter API');
    }

    const recipeContent = data.choices[0].message.content;
    console.log('Raw AI response length:', recipeContent.length);
    
    // Parse the JSON response
    let recipe;
    try {
      // First try direct parse
      recipe = JSON.parse(recipeContent);
      console.log('Direct JSON parse successful');
    } catch (parseError) {
      console.log('Direct parse failed, trying to extract JSON...');
      
      // Try to extract JSON from various formats
      const jsonMatch = recipeContent.match(/```json\n?([\s\S]*?)\n?```/) || 
                       recipeContent.match(/```\n?([\s\S]*?)\n?```/) ||
                       recipeContent.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) {
        const jsonString = jsonMatch[1] || jsonMatch[0];
        try {
          recipe = JSON.parse(jsonString);
          console.log('Extracted JSON parse successful');
        } catch (secondError) {
          console.error('Extracted JSON parse failed:', secondError);
          throw new Error('AI returned invalid JSON format');
        }
      } else {
        console.error('No JSON found in response');
        throw new Error('AI response does not contain valid JSON');
      }
    }

    // Validate required fields and provide defaults
    if (!recipe.title) recipe.title = "Generated Recipe";
    if (!recipe.ingredients) recipe.ingredients = [];
    if (!recipe.instructions) recipe.instructions = ["Mix ingredients and cook as desired."];
    if (!recipe.description) recipe.description = "A delicious recipe created based on your ingredients.";
    if (!recipe.cookingTime) recipe.cookingTime = "30 minutes";
    if (!recipe.difficulty) recipe.difficulty = "Easy";

    console.log('Recipe generated successfully:', recipe.title);

    res.status(200).json({
      success: true,
      recipe: recipe
    });

  } catch (error) {
    console.error('Error generating recipe:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to generate recipe: ' + error.message 
    });
  }
}