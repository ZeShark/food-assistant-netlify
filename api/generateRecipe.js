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
    const { 
      ingredients, 
      dietaryPreferences, 
      mealType, 
      cuisine, 
      model, // Use the model from the request (from dropdown)
      preferredIngredients = [],
      dislikedIngredients = []
    } = body;

    console.log('=== RECIPE GENERATION REQUEST ===');
    console.log('Ingredients:', ingredients);
    console.log('Selected model:', model);

    if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'Ingredients are required and must be a non-empty array' 
      });
    }

    const openRouterConfig = getOpenRouterConfig();
    
    if (!openRouterConfig.apiKey) {
      console.error('OpenRouter API key is missing');
      return res.status(500).json({
        success: false,
        error: 'OpenRouter API key is not configured'
      });
    }

    // IMPROVED PROMPT - Clear instructions about ingredient usage
    let prompt = `Create a recipe using ONLY ingredients from this list (you don't need to use them all): ${ingredients.join(', ')}.`;

    if (cuisine && cuisine !== 'Any cuisine') {
      prompt += ` Make it ${cuisine} style.`;
    }
    if (mealType && mealType !== 'Time doesn\'t matter') {
      prompt += ` This should be a ${mealType.toLowerCase()} recipe.`;
    }
    if (dietaryPreferences) {
      prompt += ` Follow these dietary preferences: ${dietaryPreferences}.`;
    }
    if (preferredIngredients && preferredIngredients.length > 0) {
      prompt += ` You can prioritize these ingredients: ${preferredIngredients.join(', ')}.`;
    }
    if (dislikedIngredients && dislikedIngredients.length > 0) {
      prompt += ` Avoid these ingredients: ${dislikedIngredients.join(', ')}.`;
    }

    prompt += `

IMPORTANT INSTRUCTIONS:
- Use ONLY ingredients from the provided list
- You do NOT need to use all ingredients - choose 5-10 that work well together
- Return ONLY valid JSON, no other text
- JSON format:
{
  "title": "Recipe Name",
  "description": "Brief description",
  "ingredients": [
    {"name": "ingredient1", "amount": "quantity"},
    {"name": "ingredient2", "amount": "quantity"}
  ],
  "instructions": [
    "Step 1 instruction",
    "Step 2 instruction"
  ],
  "cookingTime": "time estimate",
  "difficulty": "Easy/Medium/Hard"
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
        model: model, // Use the model from the request
        messages: [
          {
            role: 'system',
            content: 'You are a recipe generator. You must use ONLY ingredients from the provided list. Choose 5-10 ingredients that work well together. Return valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.7
      })
    });

    console.log('OpenRouter response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const data = await response.json();
    console.log('OpenRouter model used:', data.model);
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      throw new Error('Invalid response format from OpenRouter API');
    }

    const message = data.choices[0].message;
    
    // Check both content and reasoning fields
    let recipeContent = message.content || '';
    const reasoningContent = message.reasoning || '';
    
    console.log('Content field length:', recipeContent.length);
    console.log('Reasoning field length:', reasoningContent.length);
    console.log('Finish reason:', data.choices[0].finish_reason);

    // If content is empty but reasoning has text, use reasoning
    if (!recipeContent && reasoningContent) {
      console.log('Using reasoning content since content is empty');
      recipeContent = reasoningContent;
    }

    // If we got cut off due to length, create a fallback
    if (data.choices[0].finish_reason === 'length' && (!recipeContent || recipeContent.length < 50)) {
      console.log('Response was cut off, creating fallback recipe');
      const recipe = createFallbackRecipe(ingredients, cuisine, mealType);
      return res.status(200).json({
        success: true,
        recipe: recipe,
        note: 'Response was truncated, using fallback recipe'
      });
    }

    if (!recipeContent) {
      throw new Error('AI returned empty response');
    }

    console.log('Raw AI response preview:', recipeContent.substring(0, 200) + '...');
    
    // Try to parse the response
    let recipe = parseRecipeResponse(recipeContent, ingredients);
    
    console.log('Recipe generated successfully:', recipe.title);

    res.status(200).json({
      success: true,
      recipe: recipe
    });

  } catch (error) {
    console.error('Error generating recipe:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
}

// Keep all the helper functions the same as before...
function parseRecipeResponse(content, originalIngredients) {
  console.log('Attempting to parse recipe response...');
  
  let cleanedContent = content.trim();
  
  // Try multiple parsing strategies
  const strategies = [
    // Strategy 1: Direct JSON parse
    () => {
      console.log('Trying direct JSON parse...');
      return JSON.parse(cleanedContent);
    },
    
    // Strategy 2: Extract JSON from markdown
    () => {
      console.log('Trying markdown extraction...');
      const jsonMatch = cleanedContent.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[1].trim());
      }
      throw new Error('No markdown code block found');
    },
    
    // Strategy 3: Find JSON object pattern
    () => {
      console.log('Trying JSON object extraction...');
      const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        let jsonStr = jsonMatch[0];
        // Clean common JSON issues
        jsonStr = jsonStr
          .replace(/,(\s*[}\]])/g, '$1')
          .replace(/'/g, '"')
          .replace(/([{\[,])\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:/g, '$1"$2":')
          .replace(/:\s*'([^']*)'/g, ': "$1"');
        return JSON.parse(jsonStr);
      }
      throw new Error('No JSON object pattern found');
    }
  ];

  // Try each strategy
  for (let i = 0; i < strategies.length; i++) {
    try {
      const result = strategies[i]();
      console.log(`Strategy ${i + 1} successful!`);
      return validateRecipe(result, originalIngredients);
    } catch (error) {
      console.log(`Strategy ${i + 1} failed:`, error.message);
    }
  }

  // If all parsing fails, create a recipe from the text
  console.log('All parsing failed, creating recipe from text...');
  return createRecipeFromText(content, originalIngredients);
}

function validateRecipe(recipe, originalIngredients) {
  // Ensure all required fields exist
  if (!recipe.title) {
    recipe.title = `Recipe with ${originalIngredients.slice(0, 3).join(', ')}`;
  }
  
  if (!recipe.description) {
    recipe.description = "A delicious recipe created based on your ingredients.";
  }
  
  if (!recipe.ingredients || !Array.isArray(recipe.ingredients)) {
    recipe.ingredients = originalIngredients.slice(0, 8).map(ing => ({ 
      name: ing, 
      amount: "as needed" 
    }));
  }
  
  // Validate that ingredients come from the original list
  if (recipe.ingredients && Array.isArray(recipe.ingredients)) {
    recipe.ingredients = recipe.ingredients.map(ing => {
      if (typeof ing === 'string') {
        return { name: ing, amount: "as needed" };
      }
      if (ing.name && !originalIngredients.includes(ing.name)) {
        console.log(`Warning: AI used ingredient not in list: ${ing.name}`);
      }
      return ing;
    });
  }
  
  if (!recipe.instructions || !Array.isArray(recipe.instructions)) {
    recipe.instructions = [
      "Combine all ingredients together.",
      "Cook according to your preferred method.",
      "Season to taste and serve."
    ];
  }
  
  if (!recipe.cookingTime) {
    recipe.cookingTime = "30 minutes";
  }
  
  if (!recipe.difficulty) {
    recipe.difficulty = "Medium";
  }
  
  return recipe;
}

function createRecipeFromText(text, originalIngredients) {
  console.log('Creating fallback recipe from text...');
  
  // Try to extract information from the text
  let title = `Recipe with ${originalIngredients.slice(0, 3).join(', ')}`;
  let description = "A delicious recipe created based on your ingredients.";
  
  // Try to find instructions in the text
  const lines = text.split('\n').filter(line => line.trim().length > 10);
  let instructions = lines.slice(0, 5).map(line => line.trim());
  
  if (instructions.length === 0) {
    instructions = [
      "Mix all ingredients together in a bowl.",
      "Cook using your preferred method until done.",
      "Adjust seasoning and serve hot."
    ];
  }
  
  return {
    title: title,
    description: description,
    ingredients: originalIngredients.slice(0, 8).map(ing => ({ name: ing, amount: "to taste" })),
    instructions: instructions,
    cookingTime: "30-45 minutes",
    difficulty: "Medium"
  };
}

function createFallbackRecipe(ingredients, cuisine, mealType) {
  const cuisines = {
    'Brazilian': 'Brazilian Feijoada',
    'Italian': 'Italian Pasta',
    'Mexican': 'Mexican Fiesta',
    'Chinese': 'Chinese Stir-fry',
    'Indian': 'Indian Curry',
    'Japanese': 'Japanese Bowl'
  };
  
  const baseTitle = cuisines[cuisine] || 'Delicious Dish';
  
  return {
    title: `${baseTitle} with ${ingredients.slice(0, 2).join(' and ')}`,
    description: `A ${cuisine || 'flavorful'} ${mealType ? mealType.toLowerCase() : 'meal'} created with your ingredients.`,
    ingredients: ingredients.slice(0, 6).map(ing => ({ name: ing, amount: "as needed" })),
    instructions: [
      "Prepare all your ingredients by washing and chopping as needed.",
      "Combine the main ingredients in a large pot or pan.",
      "Add seasonings and cook until everything is tender and flavorful.",
      "Adjust the seasoning to your taste and serve hot."
    ],
    cookingTime: "45 minutes",
    difficulty: "Medium"
  };
}