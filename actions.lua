AUF_DELAYS = {
	["Fireball"] = 1,
	["Frostbolt"] = 1,
	["Concussive Shot"] = 1,
	["Scorpid Sting"] = 1,
	["Viper Sting"] = 1,
	["Serpent Sting"] = 1,
	["Wyvern Sting"] = 1,
}

AUF_RANKS = {}

AUF_RANKS["Sunder Armor"] = {
	DURATION = {30, 30, 30, 30, 30},
}

AUF_RANKS["Challenging Shout"] = {
	DURATION = {6},
}

AUF_RANKS["Demoralizing Shout"] = {
	DURATION = {30, 30, 30, 30, 30},
}

AUF_RANKS["Mocking Blow"] = {
	DURATION = {6, 6, 6, 6, 6},
}

AUF_RANKS["Rend"] = {
	DURATION = {9, 12, 15, 18, 21, 21, 21},
}

AUF_RANKS["Thunder Clap"] = {
	DURATION = {10, 14, 18, 22, 26, 30},
}

AUF_RANKS["Polymorph"] = {
	DURATION = {20, 30, 40, 50},
}

AUF_RANKS["Fireball"] = {
	DURATION = {4, 6, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8},
}

AUF_RANKS["Frostbolt"] = {
	DURATION = {5, 6, 6, 7, 7, 8, 8, 9, 9, 9},
}

AUF_RANKS["Shackle Undead"] = {
	DURATION = {30, 40, 50},
}

AUF_RANKS["Entangling Roots"] = {
	DURATION = {12, 15, 18, 21, 24, 27},
}

AUF_RANKS["Bash"] = {
	DURATION = {2, 3, 4},
}

AUF_RANKS["Hibernate"] = {
	DURATION = {20, 30, 40},
}

AUF_RANKS["Immolation Trap"] = {
	DURATION = {15, 15, 15, 15, 15},
	EFFECT = "Immolation Trap Effect",
}

AUF_RANKS["Explosive Trap"] = {
	DURATION = {20, 20, 20},
	EFFECT = "Explosive Trap Effect",
}

AUF_RANKS["Frost Trap"] = {
	DURATION = {30},
	EFFECT = "Frost Trap Aura",
}

AUF_RANKS["Freezing Trap"] = {
	DURATION = {10, 15, 20},
	EFFECT = "Freezing Trap Effect",
}

AUF_RANKS["Scare Beast"] = {
	DURATION = {10, 15, 20},
}

AUF_RANKS["Hammer of Justice"] = {
	DURATION = {3, 4, 5, 6},
}

AUF_RANKS["Turn Undead"] = {
	DURATION = {10, 15, 20},
}

AUF_RANKS["Divine Shield"] = {
	DURATION = {10, 12},
}

AUF_RANKS["Fear"] = {
	DURATION = {10, 15, 20},
}

AUF_RANKS["Howl of Terror"] = {
	DURATION = {10, 15},
}

AUF_RANKS["Banish"] = {
	DURATION = {20, 30},
}

AUF_RANKS["Corruption"] = {
	DURATION = {12, 15, 18, 18, 18, 18, 18},
}

AUF_RANKS["Spell Lock"] = {
	DURATION = {6, 8},
}

AUF_RANKS["Seduction"] = {
	DURATION = {15},
}

AUF_RANKS["Sap"] = {
	DURATION = {25, 35, 45},
}

AUF_RANKS["Kidney Shot"] = {
	DURATION = {0, 1},
}

AUF_ACTIONS = {
	--["Sunder Armor"] = true,
	["Challenging Shout"] = true,
	["Demoralizing Shout"] = true,
	["Mocking Blow"] = true,
	["Thunder Clap"] = true,
	["Expose Armor"] = true,
	["Rupture"] = true,
	["Garrote"] = true,
	["Riposte"] = true,
	['Blackout'] = true,
	["Shadow Word: Pain"] = true,
	["Devouring Plague"] = true,
	["Vampiric Embrace"] = true,
	["Holy Fire"] = true,
	["Detect Magic"] = true,
	["Frostbolt"] = true,
	["Cone of Cold"] = true,
	["Fireball"] = true,
	["Pyroblast"] = true,
	["Flamestrike"] = true,
	["Blast Wave"] = true,
	["Faerie Fire"] = true,
	["Faerie Fire (Feral)"] = true,
	["Moonfire"] = true,
	["Serpent Sting"] = true,
	["Viper Sting"] = true,
	["Concussive Shot"] = true,
	["Wing Clip"] = true,
	['Shadowburn'] = true,
	["Immolate"] = true,
	["Corruption"] = true,
	["Curse of Agony"] = true,
	["Curse of Exhaustion"] = true,
	["Curse of the Elements"] = true,
	["Curse of Shadow"] = true,
	["Curse of Tongues"] = true,
	["Curse of Weakness"] = true,
	["Curse of Recklessness"] = true,
	["Curse of Doom"] = true,
	["Siphon Life"] = true,
	["Disarm"] = true,
	["Mortal Strike"] = true,
	["Rend"] = true,
	["Hamstring"] = true,
	["Piercing Howl"] = true,
	["Frost Shock"] = true,
	["Flame Shock"] = true,
	["Stormstrike"] = true,
	["Gouge"] = true,
	["Blind"] = true,
	["Sap"] = true,
	["Kidney Shot"] = true,
	["Cheap Shot"] = true,
	["Shackle Undead"] = true,
	["Psychic Scream"] = true,
	["Polymorph"] = true,
	["Frost Nova"] = true,
	["Entangling Roots"] = true,
	["Hibernate"] = true,
	["Feral Charge"] = true,
	["Pounce"] = true,
	["Bash"] = true,
	["Scare Beast"] = true,
	["Scatter Shot"] = true,
	["Intimidation"] = true,
	["Counterattack"] = true,
	["Scorpid Sting"] = true,
	["Wyvern Sting"] = true,
	["Entrapment"] = true,
	["Hammer of Justice"] = true,
	["Repentance"] = true,
	["Turn Undead"] = true,
	["Fear"] = true,
	["Howl of Terror"] = true,
	["Death Coil"] = true,
	["Banish"] = true,
	["Intercept"] = "Intercept Stun",
	["Hamstring"] = true,
	["Intimidating Shout"] = true,
	["Concussion Blow"] = true,
	["War Stomp"] = true,
	["Seduction"] = true,
	["Inferno Effec"] = true,
	["Spell Lock"] = true,
}