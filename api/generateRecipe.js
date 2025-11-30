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
      model = 'google/gemini-flash-1.5',
      preferredIngredients = [],
      dislikedIngredients = []
    } = body;

    console.log('=== RECIPE GENERATION REQUEST ===');
    console.log('Ingredients:', ingredients);

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

    // SIMPLER PROMPT - Less complex instructions
    let prompt = `Create a recipe using: ${ingredients.join(', ')}.`;

    if (cuisine && cuisine !== 'Any cuisine') {
      prompt += ` Cuisine: ${cuisine}.`;
    }
    if (mealType && mealType !== 'Time doesn\'t matter') {
      prompt += ` Meal type: ${mealType}.`;
    }
    if (dietaryPreferences) {
      prompt += ` Dietary: ${dietaryPreferences}.`;
    }

    prompt += ` Return ONLY JSON with title, description, ingredients array, instructions array, cookingTime, and difficulty.`;

    console.log('Sending prompt to OpenRouter...');
    console.log('Prompt:', prompt);

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
            role: 'system',
            content: 'You are a recipe generator. Respond with valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 1500,
        temperature: 0.7
        // Removed response_format as it might not be supported by all models
      })
    });

    console.log('OpenRouter response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const data = await response.json();
    console.log('OpenRouter full response:', JSON.stringify(data, null, 2));
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      throw new Error('Invalid response format from OpenRouter API');
    }

    const recipeContent = data.choices[0].message.content;
    console.log('=== RAW AI RESPONSE ===');
    console.log(recipeContent);
    console.log('=== END RAW RESPONSE ===');
    
    // Try to parse or create recipe from response
    let recipe = parseRecipeResponse(recipeContent, ingredients);
    
    console.log('Final recipe object:', JSON.stringify(recipe, null, 2));

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
    recipe.title = `Recipe with ${originalIngredients.join(', ')}`;
  }
  
  if (!recipe.description) {
    recipe.description = "A delicious recipe created based on your ingredients.";
  }
  
  if (!recipe.ingredients || !Array.isArray(recipe.ingredients)) {
    recipe.ingredients = originalIngredients.map(ing => ({ 
      name: ing, 
      amount: "as needed" 
    }));
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
  let title = "Generated Recipe";
  let description = "A recipe created based on your ingredients.";
  let instructions = [];
  
  // Try to find a title-like pattern
  const titleMatch = text.match(/"title":\s*"([^"]*)"/) || 
                    text.match(/title":\s*"([^"]*)"/) ||
                    text.match(/Recipe: ([^\n\.]+)/i) ||
                    text.match(/"([^"]*)" recipe/i);
  
  if (titleMatch) {
    title = titleMatch[1] || titleMatch[0];
  }
  
  // Try to find instructions
  const instructionLines = text.split('\n').filter(line => 
    line.match(/^\d+\./) || 
    line.match(/^•/) ||
    line.match(/^Step \d+/i) ||
    (line.length > 20 && !line.match(/[{}":]/))
  );
  
  if (instructionLines.length > 0) {
    instructions = instructionLines.slice(0, 6).map(line => 
      line.replace(/^\d+\.\s*/, '')
          .replace(/^•\s*/, '')
          .replace(/^Step \d+:\s*/i, '')
          .trim()
    );
  }
  
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
    ingredients: originalIngredients.map(ing => ({ name: ing, amount: "to taste" })),
    instructions: instructions,
    cookingTime: "30-45 minutes",
    difficulty: "Medium"
  };
}