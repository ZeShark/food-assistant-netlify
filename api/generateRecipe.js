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
    const { ingredients, dietaryPreferences, mealType, cuisine, model = 'microsoft/wizardlm-2-8x22b' } = body;

    if (!ingredients || !Array.isArray(ingredients)) {
      return res.status(400).json({ error: 'Ingredients are required and must be an array' });
    }

    const openRouterConfig = getOpenRouterConfig();
    
    // Simplified prompt that's more likely to return valid JSON
    const prompt = `Create a recipe using: ${ingredients.join(', ')}
${cuisine ? `Style: ${cuisine}` : ''}${mealType ? `, ${mealType}` : ''}${dietaryPreferences ? `, ${dietaryPreferences}` : ''}
${preferredIngredients ? `Preferred ingredients: ${preferredIngredients.join(', ')}` : ''}
${dislikedIngredients ? `Avoid: ${dislikedIngredients.join(', ')}` : ''}

Return ONLY this JSON, no other text:
{
  "title": "Name",
  "description": "Brief description", 
  "ingredients": [{"name": "ing", "amount": "amt"}],
  "instructions": ["Step 1", "Step 2"],
  "cookingTime": "XX min",
  "difficulty": "Easy/Medium/Hard"
}`;

    console.log('Sending request to OpenRouter with model:', model);
    
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterConfig.apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': openRouterConfig.referer,
        'X-Title': openRouterConfig.title
      },
      body: JSON.stringify({
        model: model,
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
    console.log('Raw AI response:', recipeContent);
    
    // Better JSON parsing with fallback
    let recipe;
    try {
      // First try direct parse
      recipe = JSON.parse(recipeContent);
    } catch (parseError) {
      console.log('Direct parse failed, trying to extract JSON...');
      
      // Try to extract JSON from markdown code blocks or other wrappers
      const jsonMatch = recipeContent.match(/```json\n?([\s\S]*?)\n?```/) || 
                       recipeContent.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) {
        const jsonString = jsonMatch[1] || jsonMatch[0];
        recipe = JSON.parse(jsonString);
      } else {
        // If all else fails, create a basic recipe from the text
        console.log('JSON extraction failed, creating fallback recipe');
        recipe = {
          title: "Generated Recipe",
          description: "AI-generated recipe based on your ingredients",
          ingredients: ingredients.map(ing => ({ name: ing, amount: "to taste" })),
          instructions: ["Mix all ingredients together and cook as desired."],
          cookingTime: "30 minutes",
          difficulty: "Easy"
        };
      }
    }

    console.log('Final recipe object:', recipe);

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