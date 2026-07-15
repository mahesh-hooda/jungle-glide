(() => {
  const config = window.LEADERBOARD_CONFIG || {};
  const apiUrl = String(config.supabaseUrl || '').replace(/\/$/, '');
  const apiKey = String(config.supabasePublishableKey || '');

  const normalizeName = value => String(value || '')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/[^A-Za-z0-9 _-]/g, '')
    .slice(0, 18);

  const isConfigured = () => /^https:\/\/[^/]+\.supabase\.co$/.test(apiUrl) && apiKey.length > 20;
  const headers = () => ({
    apikey: apiKey,
    Authorization: `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  });

  async function submitScore(playerName, score) {
    const response = await fetch(`${apiUrl}/rest/v1/rpc/submit_score`, {
      method: 'POST', headers: headers(),
      body: JSON.stringify({ p_player_name: normalizeName(playerName), p_score: Math.min(99, Math.max(0, Number(score) || 0)) })
    });
    if (!response.ok) throw new Error((await response.json().catch(() => ({}))).message || 'Leaderboard score submission failed.');
    const rows = await response.json();
    if (!rows[0]) throw new Error('Leaderboard did not return a rank.');
    return rows[0];
  }

  async function registerPlayer(playerName) {
    const response = await fetch(`${apiUrl}/rest/v1/rpc/register_player`, {
      method: 'POST', headers: headers(),
      body: JSON.stringify({ p_player_name: normalizeName(playerName) })
    });
    if (!response.ok) throw new Error((await response.json().catch(() => ({}))).message || 'That player name is unavailable.');
    const rows = await response.json();
    if (!rows[0]) throw new Error('Could not reserve that player name.');
    return rows[0];
  }

  async function fetchTopPlayers() {
    const query = 'select=player_name,best_score,games_played&order=best_score.desc,updated_at.asc&limit=5';
    const response = await fetch(`${apiUrl}/rest/v1/player_best_scores?${query}`, { headers: headers() });
    if (!response.ok) throw new Error('Leaderboard query failed.');
    return response.json();
  }

  window.Leaderboard = { isConfigured, normalizeName, registerPlayer, submitScore, fetchTopPlayers };
})();
