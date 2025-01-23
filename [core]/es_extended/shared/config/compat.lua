Config.Compat = {
	-- Use the v1.13.0 Core.SavePlayers function.
	-- The new Core.SavePlayers function introduces significant performance improvements by avoiding native calls,
	-- reducing thread hitches commonly experienced on larger servers during player saves.
	--
	-- While this doesn't break compatibility with any user scripts, it may still lead to different behaviour than you would expect.
	--
	-- There are trade-offs to consider:
	-- 1. If a player or the server crashes, their health, armor, and position may not be saved.
	--    - Client crashes may lead to unsaved data.
	--    - Server crashes, however, will most definitely result in data loss for affected players.
	--
	-- For larger servers, the performance benefits might outweigh these risks,
	-- especially if frequent thread hitches are an issue.
	--
	-- Note: Do not enable this setting unless you fully understand the implications.
	useV13SavePlayers = false,
}
