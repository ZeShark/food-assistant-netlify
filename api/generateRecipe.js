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

    // IMPROVED PROMPT - More explicit about JSON format
    let prompt = `Create a recipe using these ingredients: ${ingredients.join(', ')}.`;

    if (cuisine && cuisine !== 'Any cuisine') {
      prompt += ` Make it a ${cuisine} style recipe.`;
    }
    if (mealType && mealType !== 'Time doesn\'t matter') {
      prompt += ` This should be a ${mealType.toLowerCase()} recipe.`;
    }
    if (dietaryPreferences) {
      prompt += ` Follow these dietary preferences: ${dietaryPreferences}.`;
    }
    if (preferredIngredients && preferredIngredients.length > 0) {
      prompt += ` You can also use these preferred ingredients: ${preferredIngredients.join(', ')}.`;
    }
    if (dislikedIngredients && dislikedIngredients.length > 0) {
      prompt += ` Avoid using these ingredients: ${dislikedIngredients.join(', ')}.`;
    }

    // STRICTER JSON FORMAT INSTRUCTIONS
    prompt += `

IMPORTANT: You MUST return ONLY valid JSON, no other text. Use this exact format:

{
  "title": "Recipe Name",
  "description": "Brief description",
  "ingredients": [
    {"name": "ingredient1", "amount": "quantity"},
    {"name": "ingredient2", "amount": "quantity"}
  ],
  "instructions": [
    "Step 1",
    "Step 2", 
    "Step 3"
  ],
  "cookingTime": "time estimate",
  "difficulty": "Easy/Medium/Hard"
}

Do not include any explanations, notes, or text outside the JSON.`;

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
            role: 'system',
            content: 'You are a recipe generator. Always respond with valid JSON only, no other text.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.3, // Lower temperature for more consistent JSON
        response_format: { type: "json_object" } // Force JSON response
      })
    });

    console.log('OpenRouter response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const data = await response.json();
    console.log('OpenRouter response received');
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      throw new Error('Invalid response format from OpenRouter API');
    }

    const recipeContent = data.choices[0].message.content;
    console.log('Raw AI response:', recipeContent);
    
    // IMPROVED PARSING - More aggressive JSON extraction
    let recipe;
    let jsonString = recipeContent.trim();
    
    // Remove any potential markdown or code blocks
    jsonString = jsonString.replace(/```json\s*/g, '');
    jsonString = jsonString.replace(/```\s*/g, '');
    jsonString = jsonString.replace(/^JSON\s*:\s*/i, '');
    
    // Try multiple parsing strategies
    try {
      // Strategy 1: Direct parse
      recipe = JSON.parse(jsonString);
      console.log('Direct JSON parse successful');
    } catch (firstError) {
      console.log('Direct parse failed, trying extraction...');
      
      // Strategy 2: Extract JSON object
      const jsonMatch = jsonString.match(/(\{[\s\S]*\})/);
      if (jsonMatch) {
        try {
          recipe = JSON.parse(jsonMatch[1]);
          console.log('Extracted JSON parse successful');
        } catch (secondError) {
          console.log('Extracted parse failed, trying manual cleanup...');
          
          // Strategy 3: Aggressive cleanup
          let cleanedJson = jsonMatch[1]
            .replace(/,(\s*[}\]])/g, '$1') // Remove trailing commas
            .replace(/'/g, '"') // Replace single quotes
            .replace(/(\w+):/g, '"$1":') // Quote unquoted keys
            .replace(/,\s*}/g, '}')
            .replace(/,\s*]/g, ']');
            
          try {
            recipe = JSON.parse(cleanedJson);
            console.log('Cleaned JSON parse successful');
          } catch (thirdError) {
            console.error('All JSON parsing attempts failed');
            console.log('Original content:', recipeContent);
            console.log('Cleaned content:', cleanedJson);
            throw new Error('AI returned unparseable JSON format');
          }
        }
      } else {
        console.error('No JSON object found in response');
        console.log('Full response:', recipeContent);
        throw new Error('AI response does not contain valid JSON');
      }
    }

    // Validate and ensure all required fields
    if (!recipe.title) recipe.title = `Recipe with ${ingredients.join(', ')}`;
    if (!recipe.description) recipe.description = "A delicious recipe created for you.";
    if (!recipe.ingredients || !Array.isArray(recipe.ingredients)) {
      recipe.ingredients = ingredients.map(ing => ({ name: ing, amount: "to taste" }));
    }
    if (!recipe.instructions || !Array.isArray(recipe.instructions)) {
      recipe.instructions = [
        "Combine all ingredients in a mixing bowl.",
        "Cook according to your preferred method.",
        "Season to taste and serve."
      ];
    }
    if (!recipe.cookingTime) recipe.cookingTime = "30-45 minutes";
    if (!recipe.difficulty) recipe.difficulty = "Medium";

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