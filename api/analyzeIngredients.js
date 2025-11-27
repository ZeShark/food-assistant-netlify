import { getHuggingFaceConfig } from './utils/apiConfig.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { ingredients, analysisType = 'nutrition' } = req.body;

    if (!ingredients || !Array.isArray(ingredients)) {
      return res.status(400).json({ error: 'Ingredients are required and must be an array' });
    }

    const huggingFaceConfig = getHuggingFaceConfig();
    
    // Use Hugging Face for ingredient analysis
    // You can use models like: microsoft/DialoGPT-medium or other relevant models
    const prompt = `Analyze these ingredients for ${analysisType}: ${ingredients.join(', ')}. 
    Provide insights about nutritional value, potential substitutions, or recipe suggestions.`;

    const response = await fetch(
      'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium',
      {
        headers: {
          Authorization: `Bearer ${huggingFaceConfig.apiKey}`,
          'Content-Type': 'application/json',
        },
        method: 'POST',
        body: JSON.stringify({
          inputs: prompt,
          parameters: {
            max_length: 500,
            temperature: 0.7
          }
        }),
      }
    );

    if (!response.ok) {
      throw new Error(`Hugging Face API error: ${response.status}`);
    }

    const result = await response.json();
    
    res.status(200).json({
      success: true,
      analysis: result,
      ingredients: ingredients
    });

  } catch (error) {
    console.error('Error analyzing ingredients:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to analyze ingredients: ' + error.message 
    });
  }
}