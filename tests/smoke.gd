extends SceneTree

const Game = preload("res://src/game.gd")

func _initialize() -> void:
	var game = Game.new()
	game.setup(42)
	assert(game.players.size() == 4)
	assert(game.tiles.size() == 40)
	game.players[0].position = 1
	game.phase = "buy"
	game.buy()
	assert(game.tiles[1].owner == 0)
	assert(game.players[0].cash == 1440)
	game.players[1].position = 1
	game.current = 1
	game.last_roll = [1, 2]
	game.land()
	assert(game.players[1].cash == 1488)
	assert(game.players[0].cash == 1452)
	game.go_to_jail()
	assert(game.players[1].position == 10 and game.players[1].jail == 1)
	for seed_value in range(1, 101):
		game.setup(seed_value)
		var steps := 0
		while game.winner < 0 and steps < 10000:
			match game.phase:
				"auction":
					var actor: int = game.auction.turn
					game.auction_action(game.auction.bid < game.tiles[game.auction.tile].price and game.players[actor].cash > game.auction.bid + 200)
				"roll": game.roll()
				"buy":
					if game.bot_buy(): game.buy()
					else: game.skip_buy()
				"end": game.end_turn()
			steps += 1
		assert(game.current >= 0 and game.current < 4)
		assert(game.phase in ["roll", "buy", "end", "auction"])
	print("Smoke test: mua, thuê, tù và 100 mô phỏng giới hạn bước")
	quit()
