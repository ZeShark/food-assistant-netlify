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
    const { ingredients, dietaryPreferences, mealType, cuisine, model = 'google/gemini-flash-1.5' } = body; // Default model

    if (!ingredients || !Array.isArray(ingredients)) {
      return res.status(400).json({ error: 'Ingredients are required and must be an array' });
    }

    const openRouterConfig = getOpenRouterConfig();
    
    const prompt = `Create a detailed recipe with the following requirements:
    
INGREDIENTS TO USE: ${ingredients.join(', ')}
DIETARY PREFERENCES: ${dietaryPreferences || 'None'}
MEAL TYPE: ${mealType || 'Any'}
CUISINE: ${cuisine || 'Any'}

Please provide the recipe in JSON format with the following structure:
{
  "title": "Recipe title",
  "description": "Brief description",
  "ingredients": [
    {"name": "ingredient name", "amount": "amount with unit"}
  ],
  "instructions": [
    "Step 1...",
    "Step 2..."
  ],
  "cookingTime": "XX minutes",
  "difficulty": "Easy/Medium/Hard",
  "nutritionalInfo": {
    "calories": "approx calories",
    "protein": "approx protein",
    "carbs": "approx carbs"
  }
}`;

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterConfig.apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': openRouterConfig.referer,
        'X-Title': openRouterConfig.title
      },
      body: JSON.stringify({
        model: model, // Use the selected model
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.7
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OpenRouter API error:', response.status, errorText);
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const data = await response.json();
    const recipeContent = data.choices[0].message.content;
    
    let recipe;
    try {
      recipe = JSON.parse(recipeContent);
    } catch (parseError) {
      console.error('Error parsing AI response:', parseError);
      const jsonMatch = recipeContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        recipe = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('AI response is not valid JSON');
      }
    }

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