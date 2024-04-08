extends BaseStartDialog

var DEFAULT_DIALOG_TEXT_LIST: Array = [
	"Yo, what's up dude? It's strange seeing a new face after so much time. What are you doing down here?",
	"Me? Well, I've been in this place for so long is not like I have a choice anymore",
	"You seem lost, so lemme give you a word of advice: don't get into Ongard's place with that light stick of yours. He's sleeping and you probably don't want to piss him off",
	"I'm telling ya, that's the voice of experience talking to you right now HAHAHAHAHAHAHAHAHAHAHAHAHAHA",
	"HA",
	"HA",
	"HA",
	"Wait, what do you mean you can't turn it off? You just turned it on, right? I heard it",
	"Anyway, if you do make the mistake of going in there as you are right now, remember that you can press Shift to walk. That might make 'not dying' a little bit easier",
	"Not that it helped me, really. Never been good at this kind of stuff",
	"Also, once you get in there there's only one way of getting out: defeating the boss",
	"...or just getting eaten by him. You don't seem very edible though, so once you go in it might be a while before you can go back out. Not that there's much to do around here but, ya know, I'm telling you just in case",
	"Well, good luck dude. You gonna need it",
]
var PREVIOUS_FINISHED_DIALOG_TEXT_LIST: Array = [
	"You came back? Too scared to try your luck?",
	"I mean, I think you should go in. Couldn't hurt to give it a try",
	"...actually, scratch that. It could hurt. It will hurt. Like a lot",
	"But they say pain makes us feel alive, right? Though it's been a while since I felt that way HAHAHAHAHA",
	"Get in there and show him who's boss",
]
var PREVIOUS_UNFINISHED_DIALOG_TEXT_LIST: Array = [
	"Huh? You're back? First you cut me off mid-sentence, now you want to talk to me again?",
	"You're lucky I'm bored out of my mind right now, or else I wouldn't be talking to you",
	"What I was saying is, the only way out of here is through Ongard's den. With your light stick turned on, you will have to deal with him if you wanna get out of here",
	"Use Shift to walk, maybe that'll make things easier",
	"Now get in there and leave me be",
]
var BOSS_NORMAL_DEFEATED_DIALOG_TEXT_LIST: Array = [
	"WAIT WHAT? YOU DEFEATED ONGARD? FOR REAL?",
	"You're full of surprises dude. Everybody I've seen pass by down here has never come back",
	"Well, there's a first time for everything I guess. Though I don't believe he's dead yet, so watch where you go. You might find him again, and if you do, he'll most certainly still have the will to fight. What's worse, he'll have a will to fight AND he'll also be really pissed off at you, so it will be even harder for you",
	"Just... Leave him be, I guess. He probably is deeper inside the caves, just up of where you will exit from if you continue exploring the dungeon",
	"How do I know that? Well, I've been there. With my old party. It's his personal room inside this place. He is so happy to get visitors, he shows them a full tour of his stomach, free of charge. Cool guy, ain't he?",
	"Don't say I didn't warn ya. Just go down and save yourself the trouble. You already performed a miracle here, just try to get out as fast as posible",
	"Good luck getting outside. I'll stay here for the time being, I've gotten quite used to the soil in this place. I've also made lots of worm friends. They are really cute",
]
var BOSS_HARDEST_DEFEATED_DIALOG_TEXT_LIST: Array = [
	"WAIT WHAT? YOU DEFEATED ONGARD? FOR REAL?",
	"Wait, what do you mean you didn't fight him? YOU JUST DODGED UNTIL HE GOT BORED? ARE YOU KIDDING ME?",
	"You're full of surprises dude. Everybody I've seen pass by down here has never come back",
	"Well, if he left you might find him by taking the path up as you leave the room you just were in",
	"How do I know that? Well, I've been there. With my old party. It's his personal room inside this place. He is so happy to get visitors, he shows them a full tour of his stomach, free of charge. Cool guy, ain't he?",
	"Since he let you live, he might just tolerate your presence in there though. You could even become friends! Doesn't that sound nice? Being friends with a human-killing machine? He might even show you the way out",
	"So good luck getting outside. I'll stay here for the time being, I've gotten quite used to the soil in this place. I've also made lots of worm friends. They are really cute",
]

func _ready() -> void:
	Settings.connect("game_statistic_updated", self, "_on_game_statistic_updated")
	dialog_text_list = DEFAULT_DIALOG_TEXT_LIST
	_check_level0_enemy_defeated()

func _update_dialog_previous_finished() -> void:
	if dialog_text_list == DEFAULT_DIALOG_TEXT_LIST:
		dialog_text_list = PREVIOUS_FINISHED_DIALOG_TEXT_LIST

func _update_dialog_previous_unfinished() -> void:
	if dialog_text_list == DEFAULT_DIALOG_TEXT_LIST:
		dialog_text_list = PREVIOUS_UNFINISHED_DIALOG_TEXT_LIST

func _on_game_statistic_updated(statistic: String, value) -> void:
	if statistic == "level0_enemy_defeated" and value:
		dialog_text_list = BOSS_NORMAL_DEFEATED_DIALOG_TEXT_LIST
	if statistic == "ongard_hardest_times_won" and value > 0:
		dialog_text_list = BOSS_HARDEST_DEFEATED_DIALOG_TEXT_LIST

func _check_level0_enemy_defeated() -> void:
	if Settings.get_game_statistic("level0_enemy_defeated", false):
		if Settings.get_game_statistic("ongard_hardest_times_won", 0) > 0:
			dialog_text_list = BOSS_HARDEST_DEFEATED_DIALOG_TEXT_LIST
		else:
			dialog_text_list = BOSS_NORMAL_DEFEATED_DIALOG_TEXT_LIST
