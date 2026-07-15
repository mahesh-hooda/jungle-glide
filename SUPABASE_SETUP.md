# Shared leaderboard setup

This game is ready for a shared Supabase leaderboard, but a Supabase project must be created under your account before scores can be stored online.

1. Create a project at [Supabase](https://supabase.com/dashboard).
2. In **SQL Editor**, run the complete contents of `database-setup.sql`.
3. In the project's **Connect** dialog, copy the Project URL and the **publishable** key (a legacy `anon` key also works).
4. Paste both values into `backend-config.js`. Do not use a `service_role` or secret key.
5. Upload every project file to GitHub Pages. The game reserves a unique player name before the first flight, saves each player's best score, and shows their global rank after game over.

The name-only design is intentionally lightweight; it is not an authenticated anti-cheat system. The database caps scores at 99, but determined users could submit scores manually. Add Supabase Auth and a server-side score verifier later if competitive integrity matters.
