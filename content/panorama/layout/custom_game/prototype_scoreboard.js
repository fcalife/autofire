CustomNetTables.SubscribeNetTableListener("game_state", UpdateScoreboard);
GameEvents.Subscribe("show_boon_choice", ShowBoonChoice);

$('#round_header').SetDialogVariableInt("round", 1);

function UpdateScoreboard() {
	let round_info = CustomNetTables.GetTableValue("game_state", "round_info");
	let round_timer = CustomNetTables.GetTableValue("game_state", "next_round_timer");

	$('#round_header').SetDialogVariableInt("round", round_info.round_number);
	$('#round_sub_header').text = $.Localize("#" + round_info.round_enemy) + " x" + round_info.round_count;

	if (round_timer.next_round_timer > 0) {
		$('#round_timer').visible = true;
		$('#round_timer').text = round_timer.next_round_timer;
	} else {
		$('#round_timer').visible = false;
	}
}

function ShowBoonChoice(keys) {
	$('#boon_container').visible = true;
	$('#boon_choice_damage').visible = false;
	$('#boon_choice_range').visible = false;
	$('#boon_choice_speed').visible = false;
	$('#boon_choice_health').visible = false;
	$('#boon_choice_armor').visible = false;
	$('#boon_choice_movement').visible = false;
	$('#boon_choice_cooldown').visible = false;
	$('#boon_choice_bullet').visible = false;
	$('#boon_choice_multishot').visible = false;
	$('#boon_choice_crit_up').visible = false;
	$('#boon_choice_crit_pow_up').visible = false;

	for (var i = 1; i <= 3; i++) {
		$(`#boon_choice_${keys[i]}`).visible = true;
	}
}

function PickBoon(boon) {
	$('#boon_container').visible = false;
	GameEvents.SendCustomGameEventToServer("boon_selected", {boon_name: boon});
}

(function () {})();