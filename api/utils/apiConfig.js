// API configuration utility

export function getOpenRouterConfig() {
  return {
    apiKey: process.env.OPENROUTER_API_KEY,
    referer: process.env.OPENROUTER_REFERER || 'https://food-assistant.vercel.app',
    title: process.env.OPENROUTER_TITLE || 'Food Assistant'
  };
}

export function getHuggingFaceConfig() {
  return {
    apiKey: process.env.HUGGINGFACE_API_KEY
  };
}

export function validateApiKeys() {
  const errors = [];
  
  if (!process.env.OPENROUTER_API_KEY) {
    errors.push('OPENROUTER_API_KEY is not set');
  }
  
  if (!process.env.HUGGINGFACE_API_KEY) {
    errors.push('HUGGINGFACE_API_KEY is not set');
  }
  
  return errors;
}