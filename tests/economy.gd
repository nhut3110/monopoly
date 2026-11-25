extends SceneTree

const Game = preload("res://src/game.gd")

func check(value: bool, description: String) -> void:
	if not value:
		push_error(description)
		quit(1)
		assert(false, description)

func _initialize() -> void:
	var game = Game.new()
	game.setup(42)
	game.tiles[1].owner = 0
	game.tiles[3].owner = 0
	check(game.owns_group(0, 0), "Trọn bộ")
	check(game.build(1, 0), "Xây nhà")
	check(not game.build(1, 0), "Xây đều")
	check(game.build(3, 0), "Xây ô còn lại")
	check(game.rent_for(1) == 36, "Tiền thuê tăng theo cấp")
	check(not game.mortgage(1, 0), "Không thế chấp khi nhóm có nhà")
	check(game.sell_level(1, 0) and game.sell_level(3, 0), "Bán công trình")
	check(game.mortgage(1, 0) and game.rent_for(1) == 0, "Đất thế chấp không thu tiền thuê")
	check(game.mortgage(1, 0), "Chuộc đất")
	var restored = Game.new()
	check(restored.restore(game.snapshot()), "Khôi phục snapshot")
	check(restored.snapshot() == game.snapshot(), "Trạng thái giống nhau sau khôi phục")
	game.roll()
	restored.roll()
	check(game.last_roll == restored.last_roll, "RNG tiếp tục giống nhau")
	game.setup(8)
	game.players[0].position = 1
	game.phase = "buy"
	game.skip_buy()
	game.auction_action(true)
	for step in range(3): game.auction_action(false)
	check(game.phase == "end" and game.tiles[1].owner == 0 and game.players[0].cash == 1490, "Đấu giá có người thắng")
	game.setup(7)
	game.players[0].position = 1
	game.phase = "buy"
	game.skip_buy()
	for step in range(4): game.auction_action(false)
	check(game.phase == "end" and game.tiles[1].owner == -1, "Đấu giá không có giá trả")
	game.setup(3)
	game.tiles[1].owner = 1
	check(not game.buy_from_bot(1, 1), "Bot từ chối giá thấp")
	check(game.buy_from_bot(1, game.trade_price(1)), "Mua lại tài sản")
	game.players[0].cash = 0
	check(game.pay(0, -1, 25) and game.tiles[1].mortgaged, "Thanh lý trước phá sản")
	print("Economy: xây, thuê, thế chấp, snapshot, RNG, đấu giá, giao dịch và nợ đã qua")
	quit()
