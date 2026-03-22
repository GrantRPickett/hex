extends GdUnitTestSuite

# Extended tests for TurnSystem covering functions not included in test_turn_system.gd:
#   - peek_next_index
#   - move_index_to_front
#   - reset_turns_taken_this_round

var _ts: TurnSystem

func before_test() -> void:
	_ts = auto_free(TurnSystem.new())

# --- peek_next_index ---

func test_peek_next_index_empty_queue_returns_minus_one() -> void:
	assert_int(_ts.peek_next_index()).is_equal(-1)

func test_peek_next_index_single_item() -> void:
	_ts.set_turn_queue([7])
	assert_int(_ts.peek_next_index()).is_equal(7)

func test_peek_next_index_multiple_items_returns_first() -> void:
	_ts.set_turn_queue([3, 1, 5])
	assert_int(_ts.peek_next_index()).is_equal(3)

func test_peek_next_index_does_not_consume() -> void:
	_ts.set_turn_queue([2, 4])
	_ts.peek_next_index()
	_ts.peek_next_index()
	# Queue should still have 2 items
	assert_int(_ts.get_queue_size()).is_equal(2)

# --- move_index_to_front ---

func test_move_index_to_front_swaps_with_position_zero() -> void:
	# move_index_to_front(target, list_position) swaps _turn_queue[0] and _turn_queue[list_position]
	# then sets _turn_queue[0] = target
	_ts.set_turn_queue([10, 20, 30])
	_ts.move_index_to_front(99, 1)
	var q = _ts.get_turn_queue()
	# Position 0 should now be 99
	assert_int(q[0]).is_equal(99)
	# Position 1 should contain what was at index 0 (10)
	assert_int(q[1]).is_equal(10)

func test_move_index_to_front_position_zero_is_noop() -> void:
	# list_position <= 0 is guarded by: if list_position > 0 and list_position < queue.size()
	_ts.set_turn_queue([10, 20, 30])
	_ts.move_index_to_front(99, 0)
	var q = _ts.get_turn_queue()
	# No change expected
	assert_int(q[0]).is_equal(10)

func test_move_index_to_front_out_of_bounds_position_is_noop() -> void:
	_ts.set_turn_queue([10, 20])
	# position 5 is out of bounds — should do nothing
	_ts.move_index_to_front(99, 5)
	var q = _ts.get_turn_queue()
	assert_int(q[0]).is_equal(10)
	assert_int(q[1]).is_equal(20)

func test_move_index_to_front_last_valid_position() -> void:
	_ts.set_turn_queue([1, 2, 3, 4])
	# last valid position is size-1 = 3
	_ts.move_index_to_front(99, 3)
	var q = _ts.get_turn_queue()
	assert_int(q[0]).is_equal(99)
	# Previously q[3] = 4 is now replaced by original q[0] = 1
	assert_int(q[3]).is_equal(1)

# --- reset_turns_taken_this_round ---

func test_reset_turns_taken_this_round_clears_all_sides() -> void:
	_ts.increment_turns_taken_this_round(GameConstants.Side.PLAYER)
	_ts.increment_turns_taken_this_round(GameConstants.Side.PLAYER)
	_ts.increment_turns_taken_this_round(GameConstants.Side.ENEMY)
	_ts.increment_turns_taken_this_round(GameConstants.Side.NEUTRAL)

	_ts.reset_turns_taken_this_round()

	assert_int(_ts.get_turns_taken_this_round(GameConstants.Side.PLAYER)).is_equal(0)
	assert_int(_ts.get_turns_taken_this_round(GameConstants.Side.ENEMY)).is_equal(0)
	assert_int(_ts.get_turns_taken_this_round(GameConstants.Side.NEUTRAL)).is_equal(0)

func test_reset_turns_taken_this_round_idempotent() -> void:
	_ts.reset_turns_taken_this_round()
	_ts.reset_turns_taken_this_round()
	assert_int(_ts.get_turns_taken_this_round(GameConstants.Side.PLAYER)).is_equal(0)

func test_turns_taken_increments_correctly_after_reset() -> void:
	_ts.increment_turns_taken_this_round(GameConstants.Side.ENEMY)
	_ts.increment_turns_taken_this_round(GameConstants.Side.ENEMY)
	_ts.reset_turns_taken_this_round()
	_ts.increment_turns_taken_this_round(GameConstants.Side.ENEMY)
	assert_int(_ts.get_turns_taken_this_round(GameConstants.Side.ENEMY)).is_equal(1)
