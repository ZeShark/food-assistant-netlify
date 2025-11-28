export default async function handler(req, res) {
  res.status(200).json({
    supabaseUrl: process.env.SUPABASE_URL ? 'SET' : 'MISSING',
    supabaseKey: process.env.SUPABASE_ANON_KEY ? 'SET' : 'MISSING',
    openrouterKey: process.env.OPENROUTER_API_KEY ? 'SET' : 'MISSING',
    huggingfaceKey: process.env.HUGGINGFACE_API_KEY ? 'SET' : 'MISSING',
    allEnvKeys: Object.keys(process.env)
  });
}