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
    console.log('Raw AI response preview:', recipeContent.substring(0, 200) + '...');
    
    // Parse the JSON response with better error handling
    let recipe;
    try {
      // First try direct parse
      recipe = JSON.parse(recipeContent);
      console.log('Direct JSON parse successful');
    } catch (parseError) {
      console.log('Direct parse failed, trying to extract and clean JSON...');
      console.log('Parse error:', parseError.message);
      
      // More robust JSON extraction and cleaning
      let jsonString = recipeContent;
      
      // Remove markdown code blocks
      jsonString = jsonString.replace(/```json\s*/g, '');
      jsonString = jsonString.replace(/```\s*/g, '');
      
      // Try to find JSON object
      const jsonMatch = jsonString.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        jsonString = jsonMatch[0];
        
        // Clean common JSON issues
        jsonString = jsonString
          .replace(/,(\s*[}\]])/g, '$1') // Remove trailing commas
          .replace(/'/g, '"') // Replace single quotes with double quotes
          .replace(/(\w+):/g, '"$1":') // Add quotes to unquoted keys
          .replace(/,\s*}/g, '}') // Remove trailing commas before }
          .replace(/,\s*]/g, ']'); // Remove trailing commas before ]
        
        try {
          recipe = JSON.parse(jsonString);
          console.log('Cleaned JSON parse successful');
        } catch (secondError) {
          console.error('Cleaned JSON parse failed:', secondError.message);
          console.log('Cleaned JSON string:', jsonString);
          
          // Last resort: create a basic recipe from the response
          recipe = createFallbackRecipe(recipeContent, ingredients);
          console.log('Using fallback recipe');
        }
      } else {
        console.error('No JSON object found in response');
        recipe = createFallbackRecipe(recipeContent, ingredients);
        console.log('Using fallback recipe');
      }
    }

    // Validate required fields and provide defaults
    if (!recipe.title) recipe.title = "Generated Recipe";
    if (!recipe.ingredients || !Array.isArray(recipe.ingredients)) {
      recipe.ingredients = ingredients.map(ing => ({ name: ing, amount: "to taste" }));
    }
    if (!recipe.instructions || !Array.isArray(recipe.instructions)) {
      recipe.instructions = ["Mix all ingredients together and cook until done."];
    }
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

// Fallback function to create a basic recipe when JSON parsing fails
function createFallbackRecipe(content, ingredients) {
  // Try to extract title from content
  let title = "Generated Recipe";
  const titleMatch = content.match(/"title":\s*"([^"]*)"/) || content.match(/title":\s*"([^"]*)"/);
  if (titleMatch) title = titleMatch[1];
  
  return {
    title: title,
    description: "A recipe created based on your available ingredients.",
    ingredients: ingredients.map(ing => ({ name: ing, amount: "as needed" })),
    instructions: [
      "Combine all ingredients in a bowl.",
      "Mix well until fully incorporated.",
      "Cook according to your preferred method.",
      "Serve and enjoy!"
    ],
    cookingTime: "30 minutes",
    difficulty: "Easy"
  };
}