extends RefCounted

const MAX_MESSAGE_ROWS_PER_THREAD := 24
const MAX_TIMELINE_ROWS_PER_ACCOUNT := 12
const MAX_PUBLIC_REPLY_ROWS_PER_POST := 6
const PUBLIC_CHAIN_SOFT_GATE_STEP := 2
const PUBLIC_CHAIN_MAX_STEP := 3
const LIKE_RELATIONSHIP_PROGRESS := 0.5
const SAME_DAY_SECOND_LIKE_RELATIONSHIP_PROGRESS := 0.25
const PUBLIC_ACTION_IDS := ["reply_support", "reply_skeptic", "ask_source_public"]
const PRIVATE_ACTION_IDS := ["message_check_in", "connect", "ask_source_private", "share_thesis", "ask_tip", "accept_invite", "respond_suspicious_request"]
const ATTENTION_ASK_ACTION_IDS := ["reply_support", "reply_skeptic", "ask_source_public", "message_check_in", "ask_source_private", "share_thesis", "ask_tip"]
const RELATIONSHIP_DIALOG_REPLY_POOLS := {
	"familiar": [
		"You are asking with more structure now. For {ticker}, the useful next step is to keep the evidence and the risk in the same sentence.",
		"I can be a little more specific because you have been showing up cleanly: watch what changes, not only what confirms you.",
		"This is getting more useful. Bring the source, the failure point, and the reason {ticker} still deserves attention."
	],
	"trusted": [
		"You have earned a more direct read. The setup matters, but the discipline is knowing what would make you cut the idea quickly.",
		"Since you have been doing the work, here is the better frame: separate the catalyst, the flow, and the invalidation before you add size.",
		"I trust the way you are asking now. If {ticker} cannot survive the next public check, keep it as context instead of conviction.",
		"You are past surface questions now. Put the strongest evidence and the cleanest objection beside each other before you decide.",
		"This is the kind of question people keep answering. You are not asking for certainty; you are asking how to stay honest.",
		"At this point I will be more direct: the edge is not knowing earlier, it is updating faster when the evidence changes.",
		"If you bring the source trail and the failure point, I can help sharpen the read instead of just warning you to slow down."
	],
	"inner_circle_candidate": [
		"You are close enough to the room for the sharper version: protect your reputation first, then let the thesis compete for capital.",
		"Better access means better responsibility. Use the read to improve your process, not to skip it.",
		"You have become useful to the conversation. Bring receipts, keep the boundary clean, and people will keep opening doors.",
		"If I introduce you, I am lending a little reputation too. Bring a question that proves you understand that.",
		"Rooms open because people think you will handle context carefully. Do not make them regret that read.",
		"The deeper note is this: access is fragile. One lazy ask can close doors that took weeks to open.",
		"You are close to better conversations now. Keep your work public enough to defend and private enough to stay respectful."
	]
}
const NETWORK_SOURCE_DIALOG_REPLY_POOLS := {
	"familiar": [
		"You are asking more carefully now. For {ticker}, keep the public evidence, timing, and risk in one note.",
		"This is a better source ask. Start with what can be verified on {company}, then decide how much weight the lead deserves.",
		"I can be more useful when the question stays this specific. For {ticker}, separate the source trail from the market reaction."
	],
	"trusted": [
		"You have shown enough discipline for the sharper version: verify the public trail first, then compare whether the market reaction is ahead of the evidence.",
		"Since you have kept the boundary clean, here is the useful frame: ask what would make {ticker} less serious, not only what confirms it.",
		"This is becoming a proper source relationship. Bring the document, the date, and the failure point, and I can help you read around them.",
		"You are asking like someone who understands the boundary. I can help with context, but the conviction still has to come from your work.",
		"Good source work is boring before it is useful. Keep the timeline, the public proof, and the market reaction separated.",
		"I can be clearer now: if the story needs private pressure to sound good, it is not ready for your thesis.",
		"You have earned a better answer, so here it is: treat every source lead as a test of process, not a shortcut around it."
	],
	"inner_circle_candidate": [
		"You are close enough for better context, but the boundary stays the same: public evidence first, reputation always.",
		"Better access only helps if your process stays clean. Treat {ticker} as a case file, not a favor.",
		"You are useful to talk to now. Keep bringing receipts and I will keep the read practical.",
		"If I point you toward someone, you represent the quality of your questions. Prepare before you use that door.",
		"The inner circle version is not louder; it is cleaner, more careful, and much less forgiving of sloppy framing.",
		"You can get better context now, but do not confuse trust with permission to skip verification.",
		"I can introduce you when the ask is narrow, the thesis is written, and the boundary stays clean."
	]
}
const UNFOLLOWED_ASK_REPLY_POOL := [
	"You don't even follow me yet, but you keep asking for reads. Follow first, then bring one clean question.",
	"You are asking for more context while staying outside the feed. Follow the account first so this feels like a conversation, not a help desk.",
	"I respect the curiosity, but you keep taking without even following. Start there, then show me the work.",
	"Follow first, then ask deeper. Attention is part of the relationship too."
]
const DEFAULT_RESPONSE_POOLS := {
	"reply_support": [
		"Keep receipts and size it like a thesis, not a mood.",
		"Fair angle. Watch whether the next tape confirms it."
	],
	"reply_skeptic": [
		"Good pushback. The market usually punishes lazy certainty first.",
		"Skepticism is healthy. Bring data and people listen longer."
	],
	"ask_source_public": [
		"Public source for now. If I get a cleaner read, I will point you there.",
		"The source is still soft, but the watch item is real enough to track."
	],
	"message_check_in": [
		"DM received. Keep the asks precise and we can compare notes.",
		"I can talk, but I prefer clean setups and clear questions."
	],
	"connect": [
		"Alright, connected. I will remember the way you read the tape.",
		"Connection accepted. Let us keep it useful."
	],
	"ask_source_private": [
		"Treat {ticker} as unconfirmed until public evidence catches up.",
		"I can point you to the clean part: verify {ticker} through volume, filings, and follow-through."
	],
	"share_thesis": [
		"I read your thesis on {thesis_title}. The structure matters more than the call.",
		"Sharing the thesis helps. I can tell you are trying to build a process."
	],
	"ask_tip": [
		"No magic leak. The useful read is to watch {ticker} confirmation and volume.",
		"Treat this as a watch item, not an order: {ticker} needs follow-through."
	],
	"accept_invite": [
		"Invite noted. Show up prepared; rooms remember who asks useful questions.",
		"You can come along, but bring a clean question and do not treat access as certainty."
	],
	"respond_suspicious_request": [
		"Good answer. Keep the line clean when a request smells off.",
		"Noted. Walking away from a bad ask is part of staying in the market."
	]
}
const ACTION_DEFINITIONS := {
	"reply_support": {
		"label": "Support",
		"detail": "Public constructive reply",
		"private": false,
		"relationship_delta": 3,
		"exposure_delta": 2,
		"credibility_delta": 0
	},
	"reply_skeptic": {
		"label": "Question",
		"detail": "Public skeptical reply",
		"private": false,
		"relationship_delta": 1,
		"exposure_delta": 2,
		"credibility_delta": 1
	},
	"ask_source_public": {
		"label": "Ask source",
		"detail": "Public source check",
		"private": false,
		"relationship_delta": 2,
		"exposure_delta": 1,
		"credibility_delta": 1
	},
	"message_check_in": {
		"label": "Message",
		"detail": "Private message",
		"private": true,
		"relationship_delta": 4,
		"exposure_delta": 0,
		"credibility_delta": 0
	},
	"connect": {
		"label": "Connect",
		"detail": "Add to Network",
		"private": true,
		"relationship_delta": 6,
		"exposure_delta": 1,
		"credibility_delta": 0
	},
	"ask_source_private": {
		"label": "Ask source",
		"detail": "Private source check",
		"private": true,
		"relationship_delta": 2,
		"exposure_delta": 0,
		"credibility_delta": 2
	},
	"share_thesis": {
		"label": "Share thesis",
		"detail": "Send a thesis by DM",
		"private": true,
		"relationship_delta": 4,
		"exposure_delta": 0,
		"credibility_delta": 4
	},
	"ask_tip": {
		"label": "Ask tip",
		"detail": "Ask for a clean market read",
		"private": true,
		"relationship_delta": 2,
		"exposure_delta": 0,
		"credibility_delta": 1
	},
	"accept_invite": {
		"label": "Accept invite",
		"detail": "Accept a social event invitation",
		"private": true,
		"relationship_delta": 3,
		"exposure_delta": 2,
		"credibility_delta": 1
	},
	"respond_suspicious_request": {
		"label": "Keep it clean",
		"detail": "Respond to a suspicious request without taking the bait",
		"private": true,
		"relationship_delta": 0,
		"exposure_delta": 0,
		"credibility_delta": 3
	}
}
const DEFAULT_DIALOG_TREES := {
	"clean_intro": {
		"entry_node": "open",
		"nodes": {
			"open": {
				"account_replies": [
					"Good. Start with the part that would prove you wrong.",
					"Clean reads begin with limits. What would make you step back?"
				],
				"options": [
					{"id": "define_process", "label": "Process", "private_action_id": "message_check_in", "player_lines": ["I am trying to separate useful context from noise. What would you check first?", "I want to build the read properly before I act. Where should I start?"], "next_node": "evidence"},
					{"id": "ask_public_evidence", "label": "Evidence", "private_action_id": "ask_source_private", "public_action_id": "ask_source_public", "player_lines": ["Can you point me to the clean evidence instead of just the chatter?", "What public evidence would make this worth tracking?"], "next_node": "evidence"},
					{"id": "connect_clean", "label": "Connect", "private_action_id": "connect", "player_lines": ["Your read is useful. I want to stay connected and keep this evidence-first.", "Let's connect, but I want the conversation to stay clean."], "next_node": "trust"}
				]
			},
			"evidence": {
				"account_replies": [
					"Then watch confirmation, not certainty. The market rarely gives both.",
					"Better. A clean source only matters if the next tape agrees."
				],
				"options": [
					{"id": "state_disproof", "label": "Disproof", "private_action_id": "message_check_in", "public_action_id": "reply_skeptic", "player_lines": ["If volume fades or the filing does not confirm it, I step back.", "I will treat the idea as wrong if the follow-through disappears."], "next_node": "trust"},
					{"id": "ask_clean_read", "label": "Clean read", "private_action_id": "ask_tip", "public_action_id": "reply_support", "player_lines": ["What would you watch next without turning it into a shortcut?", "Give me the clean watch item, not a buy signal."], "next_node": "trust"},
					{"id": "bring_thesis", "label": "Thesis", "private_action_id": "share_thesis", "requirements": {"shareable_thesis": true}, "blocked_lines": ["Build a thesis first, then I can challenge the weak part.", "Bring a written thesis first; without it we are only trading vibes."], "player_lines": ["I have a thesis ready. Can you challenge the weak part?", "I want to share my thesis and hear what breaks first."], "next_node": "trust"}
				]
			},
			"trust": {
				"account_replies": [
					"That is a better way to ask. Keep showing your work.",
					"Now we are talking process instead of signals."
				],
				"options": [
					{"id": "close_loop", "label": "Close loop", "private_action_id": "message_check_in", "public_action_id": "reply_support", "player_lines": ["I will come back after the next tape gives us more information.", "I will track it and avoid forcing a trade today."], "next_node": "evidence"},
					{"id": "ask_next_context", "label": "Next context", "private_action_id": "ask_tip", "player_lines": ["What context should I bring next time so this is useful?", "What would make the next conversation more precise?"], "next_node": "evidence"},
					{"id": "share_next_thesis", "label": "Share thesis", "private_action_id": "share_thesis", "requirements": {"shareable_thesis": true}, "blocked_lines": ["Build the thesis first. I need something concrete to review.", "Write the thesis first; then we can talk about what breaks it."], "player_lines": ["I have enough structure now; I want to share the thesis and have you challenge it.", "I will bring the written thesis next, not just another question."], "next_node": "evidence"}
				]
			}
		}
	},
	"source_check": {
		"entry_node": "source",
		"nodes": {
			"source": {
				"account_replies": ["I would trust a source you can reopen tomorrow: an IDX filing, company disclosure, dated news, or a clear volume trail.", "Start with the public trail: filings, calendar dates, company disclosures, and whether volume confirms people are acting."],
				"options": [
					{"id": "ask_origin", "label": "Origin", "private_action_id": "ask_source_private", "public_action_id": "ask_source_public", "player_lines": ["Where did this read start, and what part is actually public?", "What source would you trust before treating this seriously?"], "next_node": "verify"},
					{"id": "pushback", "label": "Pushback", "private_action_id": "message_check_in", "public_action_id": "reply_skeptic", "player_lines": ["If everyone is reading the same clue, I want to know what invalidates it.", "This could be crowded. What would make you change your mind?"], "next_node": "verify"},
					{"id": "watch_only", "label": "Watch", "private_action_id": "ask_tip", "public_action_id": "reply_support", "player_lines": ["I will keep it as a watch item until evidence catches up.", "I am watching, not chasing, until confirmation shows up."], "next_node": "verify"}
				]
			},
			"verify": {
				"account_replies": ["Good. Verification beats speed when the tape is noisy.", "That is the clean habit: verify, then decide."],
				"options": [
					{"id": "file_check", "label": "Filing", "private_action_id": "ask_source_private", "public_action_id": "ask_source_public", "player_lines": ["I will check filings and volume before I trust the angle.", "I want a filing, date, or volume trail before calling this real."], "next_node": "source"},
					{"id": "thesis_check", "label": "Thesis", "private_action_id": "share_thesis", "requirements": {"shareable_thesis": true}, "blocked_lines": ["Turn it into a thesis first; then I can test the assumptions.", "Write the thesis first so the idea has a falsifiable shape."], "player_lines": ["I can turn this into a thesis and test the assumptions.", "I will write the thesis first so the idea has a falsifiable shape."], "next_node": "source"},
					{"id": "come_back", "label": "Wait", "private_action_id": "message_check_in", "public_action_id": "reply_support", "player_lines": ["I will wait for new tape before asking again.", "I will come back when the market gives us more data."], "next_node": "source"}
				]
			}
		}
	},
	"thesis_review": {
		"entry_node": "review",
		"nodes": {
			"review": {
				"account_replies": ["A thesis is useful only if it names its own failure point.", "Show me the assumption that hurts if you are wrong."],
				"options": [
					{"id": "share_structure", "label": "Share thesis", "private_action_id": "share_thesis", "requirements": {"shareable_thesis": true}, "blocked_lines": ["Build your thesis first. I cannot review a direction without structure.", "Write a thesis first; I need assumptions, not just a ticker."], "player_lines": ["I want to share my thesis and have you attack the weakest assumption.", "Can you review my thesis for structure, not just direction?"], "next_node": "challenge"},
					{"id": "ask_weakness", "label": "Weakness", "private_action_id": "message_check_in", "player_lines": ["The part I am least sure about is the follow-through. How would you test it?", "I am trying to find what breaks first before I trust it."], "next_node": "challenge"},
					{"id": "source_thesis", "label": "Source", "private_action_id": "ask_source_private", "player_lines": ["What source would make my thesis cleaner or force me to rewrite it?", "Which evidence should I check before I defend this thesis?"], "next_node": "challenge"}
				]
			},
			"challenge": {
				"account_replies": ["Better. Now your opinion has a shape the market can test.", "That is the difference between a thesis and a feeling."],
				"options": [
					{"id": "accept_challenge", "label": "Accept", "private_action_id": "message_check_in", "player_lines": ["I will rewrite it with that failure point in mind.", "I will update the thesis before I ask for another read."], "next_node": "review"},
					{"id": "ask_read", "label": "Clean read", "private_action_id": "ask_tip", "player_lines": ["What should I watch next to confirm or kill the thesis?", "What is the cleanest next signal for this thesis?"], "next_node": "review"},
					{"id": "connect_process", "label": "Connect", "private_action_id": "connect", "player_lines": ["This is useful. I want to keep comparing thesis work with you.", "Let's connect; I will bring cleaner work next time."], "next_node": "review"}
				]
			}
		}
	},
	"market_read": {
		"entry_node": "read",
		"nodes": {
			"read": {
				"account_replies": ["The move is only useful if you know what kind of move it is.", "A candle is not a thesis. Context first."],
				"options": [
					{"id": "support_context", "label": "Context", "private_action_id": "ask_tip", "public_action_id": "reply_support", "player_lines": ["I like the context, but I want the next tape to confirm it.", "This read helps, but I am not treating one move as proof."], "next_node": "follow"},
					{"id": "question_flow", "label": "Question", "private_action_id": "message_check_in", "public_action_id": "reply_skeptic", "player_lines": ["How much of this is real demand versus everyone reacting to the same headline?", "What would make you say the move is fading instead of building?"], "next_node": "follow"},
					{"id": "ask_source", "label": "Source", "private_action_id": "ask_source_private", "public_action_id": "ask_source_public", "player_lines": ["What clean source should I check before I trust this read?", "Is there a filing or public clue behind this move?"], "next_node": "follow"}
				]
			},
			"follow": {
				"account_replies": ["Good. Now wait for the market to answer.", "That is enough for now; new tape matters more than more words."],
				"options": [
					{"id": "wait_next", "label": "Wait", "private_action_id": "message_check_in", "public_action_id": "reply_support", "player_lines": ["I will wait for the next session before forcing another read.", "I will watch the follow-through instead of asking for certainty."], "next_node": "read"},
					{"id": "ask_watch", "label": "Watch item", "private_action_id": "ask_tip", "player_lines": ["What single watch item would keep this clean?", "What should I monitor without treating it as a signal?"], "next_node": "read"},
					{"id": "source_after", "label": "Verify", "private_action_id": "ask_source_private", "public_action_id": "ask_source_public", "player_lines": ["If a better source appears, I will verify before acting.", "I need cleaner evidence before this becomes conviction."], "next_node": "read"}
				]
			}
		}
	},
	"trust_building": {
		"entry_node": "trust",
		"nodes": {
			"trust": {
				"account_replies": ["You are asking better questions now.", "I will spend more time when the questions stay this clean."],
				"options": [
					{"id": "ask_room", "label": "Room", "private_action_id": "accept_invite", "requirements": {"relationship_stage": "trusted"}, "blocked_lines": ["Build more trust first. Rooms open after your questions prove useful.", "Not yet. Earn more trust before asking for an invite."], "player_lines": ["If there is a room worth joining, I will bring a clean question.", "I can join, but I want the room to stay evidence-first."], "next_node": "after"},
					{"id": "share_work", "label": "Share work", "private_action_id": "share_thesis", "requirements": {"shareable_thesis": true}, "blocked_lines": ["Bring written thesis work first. I cannot judge a blank page.", "Build the thesis first; then I can judge the process."], "player_lines": ["I will share the thesis so you can judge the process.", "I want you to challenge my written work, not just the trade idea."], "next_node": "after"},
					{"id": "ask_next", "label": "Next", "private_action_id": "ask_tip", "public_action_id": "reply_support", "player_lines": ["What should I bring next time so the conversation is useful?", "What next context would make this worth revisiting?"], "next_node": "after"}
				]
			},
			"after": {
				"account_replies": ["Bring receipts next time. That is how trust compounds.", "Good. Access is only useful when your process improves."],
				"options": [
					{"id": "ack_process", "label": "Process", "private_action_id": "message_check_in", "public_action_id": "reply_support", "player_lines": ["I will bring evidence next time, not just a hunch.", "I will keep the process clean and come back with receipts."], "next_node": "trust"},
					{"id": "ask_source_again", "label": "Source", "private_action_id": "ask_source_private", "public_action_id": "ask_source_public", "player_lines": ["I will verify the source before I take the next step.", "Point me to what is public; I will do the work from there."], "next_node": "trust"},
					{"id": "clean_boundary", "label": "Boundary", "private_action_id": "respond_suspicious_request", "player_lines": ["If anything crosses a line, I am out.", "I want access, but not enough to take a dirty request."], "next_node": "trust"}
				]
			}
		}
	},
	"suspicious_boundary": {
		"entry_node": "boundary",
		"nodes": {
			"boundary": {
				"account_replies": ["Some doors are not worth opening.", "A bad ask can ruin a good run."],
				"options": [
					{"id": "keep_clean", "label": "Keep clean", "private_action_id": "respond_suspicious_request", "player_lines": ["If the ask is not public, I am out.", "I am keeping this clean. No dirty requests."], "next_node": "safe"},
					{"id": "ask_public_only", "label": "Public only", "private_action_id": "ask_source_private", "player_lines": ["Give me only what I can verify publicly.", "If there is no public trail, I do not want it."], "next_node": "safe"},
					{"id": "walk_away", "label": "Walk away", "private_action_id": "message_check_in", "player_lines": ["I would rather miss the move than cross that line.", "I am stepping back until the read is clean."], "next_node": "safe"}
				]
			},
			"safe": {
				"account_replies": ["Good boundary. Reputation lasts longer than a hot tip.", "That answer keeps you in better rooms later."],
				"options": [
					{"id": "ack_boundary", "label": "Acknowledge", "private_action_id": "message_check_in", "player_lines": ["I will keep that line clear.", "I want my process to survive the trade."], "next_node": "boundary"},
					{"id": "clean_source", "label": "Clean source", "private_action_id": "ask_source_private", "player_lines": ["If there is a clean source, I will check that instead.", "Point me only to public evidence."], "next_node": "boundary"},
					{"id": "connect_cleanly", "label": "Connect", "private_action_id": "connect", "player_lines": ["I will connect only if we keep this clean.", "Let's stay connected, but with clear boundaries."], "next_node": "boundary"}
				]
			}
		}
	},
	"event_invite": {
		"entry_node": "invite",
		"nodes": {
			"invite": {
				"account_replies": ["There may be a room worth joining, but do not confuse access with truth.", "If you come in, bring one useful question."],
				"options": [
					{"id": "accept_clean", "label": "Accept invite", "private_action_id": "accept_invite", "requirements": {"relationship_stage": "trusted"}, "blocked_lines": ["Build more trust first. An invite only makes sense when your process is known.", "Not yet. Keep showing clean work before entering a room."], "player_lines": ["I can join, and I will bring one clean question.", "I will show up prepared and keep the room evidence-first."], "next_node": "after"},
					{"id": "ask_purpose", "label": "Purpose", "private_action_id": "message_check_in", "player_lines": ["What is the purpose of the room, and what should I prepare?", "I want to know what question would actually help there."], "next_node": "after"},
					{"id": "share_before", "label": "Share thesis", "private_action_id": "share_thesis", "requirements": {"shareable_thesis": true}, "blocked_lines": ["Build a thesis first so the room has something concrete.", "Write the thesis first; do not show up empty."], "player_lines": ["I will share my thesis first so the room has something concrete.", "Let me bring my thesis instead of showing up empty."], "next_node": "after"}
				]
			},
			"after": {
				"account_replies": ["Good. Prepared people get invited back.", "That is the right way to treat access: useful, not magical."],
				"options": [
					{"id": "confirm_prepare", "label": "Prepare", "private_action_id": "message_check_in", "player_lines": ["I will prepare before I ask for more access.", "I will bring notes, not guesses."], "next_node": "invite"},
					{"id": "ask_source", "label": "Source", "private_action_id": "ask_source_private", "player_lines": ["What public source should I check before the room?", "What should I verify before I show up?"], "next_node": "invite"},
					{"id": "clean_boundary", "label": "Boundary", "private_action_id": "respond_suspicious_request", "player_lines": ["If the room turns dirty, I am leaving.", "Access is useful only if it stays clean."], "next_node": "invite"}
				]
			}
		}
	}
}


func is_private_action(action_id: String) -> bool:
	return bool(ACTION_DEFINITIONS.get(action_id, {}).get("private", false))


func enhance_snapshot(snapshot: Dictionary, social_state: Dictionary, feed_data: Dictionary, player_theses: Dictionary, daily_action: Dictionary, day_index: int) -> Dictionary:
	var enriched: Dictionary = snapshot.duplicate(true)
	var normalized_state: Dictionary = normalize_social_state(social_state, day_index)
	var account_lookup: Dictionary = _account_lookup(snapshot.get("accounts", []))
	var account_states: Dictionary = normalized_state.get("account_states", {})
	var post_interactions: Dictionary = normalized_state.get("post_interactions", {})
	var messages: Dictionary = normalized_state.get("messages", {})
	var liked_posts: Dictionary = normalized_state.get("liked_posts", {})
	var enriched_accounts: Array = []
	for account_value in snapshot.get("accounts", []):
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value.duplicate(true)
		var account_id: String = str(account.get("id", ""))
		var account_state: Dictionary = _account_state(account_states, account_id)
		_apply_account_social_fields(account, account_state, messages.get(account_id, {}))
		enriched_accounts.append(account)
	enriched["accounts"] = enriched_accounts
	var thesis_rows: Array = _shareable_thesis_rows(player_theses)
	var enriched_posts: Array = []
	for post_value in snapshot.get("posts", []):
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value.duplicate(true)
		var post_id: String = str(post.get("id", ""))
		var account_id: String = str(post.get("account_id", ""))
		var account: Dictionary = account_lookup.get(account_id, {})
		var account_state: Dictionary = _account_state(account_states, account_id)
		var interaction: Dictionary = post_interactions.get(post_id, {})
		var liked_row: Dictionary = liked_posts.get(post_id, {}) if typeof(liked_posts.get(post_id, {})) == TYPE_DICTIONARY else {}
		var post_branch: Dictionary = _dialog_branch(normalized_state, "posts", post_id, _select_public_tree_id(feed_data, account, account_state, post), feed_data)
		var cooldown_reason: String = _dialog_cooldown_reason(post_branch, day_index)
		post["liked_by_player"] = not liked_row.is_empty()
		post["can_like"] = liked_row.is_empty()
		if not liked_row.is_empty():
			post["likes"] = int(post.get("likes", 0)) + 1
		post["interaction_options"] = _post_interaction_options(post, account_state, daily_action, thesis_rows, day_index, interaction)
		post["reply_dialog_options"] = _reply_dialog_options(feed_data, post, account, account_state, interaction, post_branch, thesis_rows, daily_action, day_index)
		post["player_replies"] = interaction.get("replies", []).duplicate(true) if typeof(interaction.get("replies", [])) == TYPE_ARRAY else []
		post["player_interaction_count"] = int(interaction.get("interaction_count", 0))
		post["conversation_step"] = int(interaction.get("conversation_step", 0))
		post["can_reply"] = cooldown_reason.is_empty() and not bool(interaction.get("concluded", false)) and int(interaction.get("conversation_step", 0)) < PUBLIC_CHAIN_MAX_STEP
		post["conversation_conclusion"] = cooldown_reason if not cooldown_reason.is_empty() else str(interaction.get("conclusion_reason", ""))
		post["cooldown_reason"] = cooldown_reason
		post["followup_unlocked"] = bool(interaction.get("followup_unlocked", false))
		post["relationship_stage"] = _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
		enriched_posts.append(post)
	enriched["posts"] = enriched_posts
	enriched["message_threads"] = _message_thread_summaries(messages, account_lookup, account_states)
	enriched["shareable_theses"] = thesis_rows
	enriched["trending_rows"] = _trending_rows(enriched_posts)
	enriched["who_to_follow"] = _who_to_follow_rows(enriched_accounts, feed_data)
	enriched["social_state_summary"] = _state_summary(account_states, messages)
	return enriched


func validate_post_interaction(_run_state, snapshot: Dictionary, post_id: String, action_id: String, thesis_id: String = "") -> Dictionary:
	var post: Dictionary = _post_by_id(snapshot.get("posts", []), post_id)
	if post.is_empty():
		return {"success": false, "message": "That Twooter post is no longer visible."}
	if post.has("can_reply") and not bool(post.get("can_reply", true)):
		return {"success": false, "message": "That public thread has run its course. Continue through Message if the contact is open to it."}
	return validate_account_action(snapshot, str(post.get("account_id", "")), action_id, thesis_id)


func validate_account_action(snapshot: Dictionary, account_id: String, action_id: String, thesis_id: String = "") -> Dictionary:
	if _account_by_id(snapshot.get("accounts", []), account_id).is_empty():
		return {"success": false, "message": "That Twooter account is not available."}
	if not ACTION_DEFINITIONS.has(action_id):
		return {"success": false, "message": "That Twooter action is not available yet."}
	if action_id == "share_thesis":
		var found_thesis: bool = false
		for thesis_value in snapshot.get("shareable_theses", []):
			if typeof(thesis_value) == TYPE_DICTIONARY and str(thesis_value.get("id", "")) == thesis_id:
				found_thesis = true
				break
		if not found_thesis:
			return {"success": false, "message": "Choose a thesis to share first."}
	return {"success": true}


func apply_post_interaction(run_state, feed_data: Dictionary, snapshot: Dictionary, post_id: String, action_id: String, thesis_id: String = "", player_reply_text: String = "") -> Dictionary:
	var post: Dictionary = _post_by_id(snapshot.get("posts", []), post_id)
	if post.is_empty():
		return {"success": false, "message": "That Twooter post is no longer visible."}
	return _apply_interaction(run_state, feed_data, snapshot, post, str(post.get("account_id", "")), action_id, thesis_id, post_id, player_reply_text)


func apply_message_action(run_state, feed_data: Dictionary, snapshot: Dictionary, account_id: String, action_id: String, thesis_id: String = "", player_message_text: String = "") -> Dictionary:
	var account: Dictionary = _account_by_id(snapshot.get("accounts", []), account_id)
	if account.is_empty():
		return {"success": false, "message": "That Twooter account is not available."}
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var post_stub: Dictionary = {
		"id": "message|%s|%d|%s" % [account_id, run_state.day_index, action_id],
		"account_id": account_id,
		"account_name": str(account.get("display_name", "")),
		"account_handle": str(account.get("handle", "")),
		"target_company_id": str(profile.get("target_company_id", "")),
		"target_ticker": str(profile.get("target_ticker", "")),
		"target_company_name": str(profile.get("target_company_name", "")),
		"tone": "mixed",
		"category": "message"
	}
	return _apply_interaction(run_state, feed_data, snapshot, post_stub, account_id, action_id, thesis_id, "", player_message_text)


func apply_follow_account(run_state, snapshot: Dictionary, account_id: String) -> Dictionary:
	var account: Dictionary = _account_by_id(snapshot.get("accounts", []), account_id)
	if account.is_empty():
		return {"success": false, "message": "That Twooter account is not available."}
	var state: Dictionary = normalize_social_state(run_state.get_twooter_social_state(), run_state.day_index)
	var account_states: Dictionary = state.get("account_states", {})
	var account_state: Dictionary = _account_state(account_states, account_id)
	var was_following: bool = bool(account_state.get("following", false))
	account_state["following"] = true
	account_state["unfollowed_ask_count"] = 0
	var relationship_delta: int = 0 if was_following else 1
	account_state["relationship"] = clampi(int(account_state.get("relationship", 0)) + relationship_delta, 0, 100)
	account_state["exposure"] = clampi(int(account_state.get("exposure", 0)) + (0 if was_following else 1), 0, 100)
	account_state["importance"] = _importance_score(account_state)
	account_state["relationship_stage"] = _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	account_states[account_id] = account_state
	state["account_states"] = account_states
	if not was_following:
		_record_timeline_row(state, account_id, "follow", "Followed the account.", "", run_state.day_index)
	run_state.set_twooter_social_state(state)
	return {
		"success": true,
		"message": "Following %s." % str(account.get("display_name", "account")),
		"account_state": account_state.duplicate(true),
		"relationship_delta": relationship_delta,
		"network_changed": false
	}


func apply_like_post(run_state, snapshot: Dictionary, post_id: String) -> Dictionary:
	var post: Dictionary = _post_by_id(snapshot.get("posts", []), post_id)
	if post.is_empty():
		return {"success": false, "message": "That Twooter post is no longer visible."}
	var account_id: String = str(post.get("account_id", ""))
	var account: Dictionary = _account_by_id(snapshot.get("accounts", []), account_id)
	if account.is_empty():
		return {"success": false, "message": "That Twooter account is not available."}
	var state: Dictionary = normalize_social_state(run_state.get_twooter_social_state(), run_state.day_index)
	var liked_posts: Dictionary = state.get("liked_posts", {})
	if liked_posts.has(post_id):
		return {
			"success": false,
			"message": "You already liked that Twooter post.",
			"already_liked": true
		}
	var account_states: Dictionary = state.get("account_states", {})
	var account_state: Dictionary = _account_state(account_states, account_id)
	liked_posts[post_id] = {
		"account_id": account_id,
		"day_index": run_state.day_index
	}
	state["liked_posts"] = liked_posts
	account_state["likes_given"] = max(int(account_state.get("likes_given", 0)) + 1, 0)
	account_state["last_like_day_index"] = run_state.day_index
	var progress_delta: float = _like_relationship_progress_delta(state, account_id, run_state.day_index)
	var progress: float = float(clamp(float(account_state.get("like_relationship_progress", 0.0)) + progress_delta, 0.0, 8.0))
	var relationship_delta: int = int(floor(progress))
	progress -= float(relationship_delta)
	account_state["like_relationship_progress"] = progress
	account_state["relationship"] = clampi(int(account_state.get("relationship", 0)) + relationship_delta, 0, 100)
	account_state["exposure"] = clampi(int(account_state.get("exposure", 0)) + _like_exposure_delta(state, account_id, run_state.day_index), 0, 100)
	account_state["importance"] = _importance_score(account_state)
	account_state["relationship_stage"] = _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	account_states[account_id] = account_state
	state["account_states"] = account_states
	_increment_public_daily_count(state, account_id, "like", run_state.day_index)
	_record_timeline_row(state, account_id, "like_post", _liked_post_memory_text(post), post_id, run_state.day_index)
	run_state.set_twooter_social_state(state)
	return {
		"success": true,
		"message": "Liked %s's post." % str(account.get("display_name", "the account")),
		"account_state": account_state.duplicate(true),
		"relationship_delta": relationship_delta,
		"relationship_progress": progress,
		"relationship_progress_added": progress_delta,
		"likes_given": int(account_state.get("likes_given", 0)),
		"network_changed": false
	}


func get_message_thread(social_state: Dictionary, accounts: Array, account_id: String, day_index: int, shareable_theses: Array = [], feed_data: Dictionary = {}, daily_action: Dictionary = {}) -> Dictionary:
	var state: Dictionary = normalize_social_state(social_state, day_index)
	var account: Dictionary = _account_by_id(accounts, account_id)
	if account.is_empty():
		return {"account": {}, "rows": [], "dialog_options": []}
	var messages: Dictionary = state.get("messages", {})
	var thread: Dictionary = messages.get(account_id, {})
	var account_states: Dictionary = state.get("account_states", {})
	var account_state: Dictionary = _account_state(account_states, account_id)
	var account_branch: Dictionary = _dialog_branch(state, "accounts", account_id, _select_message_tree_id(feed_data, account, account_state, thread, shareable_theses), feed_data)
	return {
		"account": account.duplicate(true),
		"rows": thread.get("rows", []).duplicate(true) if typeof(thread.get("rows", [])) == TYPE_ARRAY else [],
		"unread_count": int(thread.get("unread_count", 0)),
		"dialog_options": _message_dialog_options(feed_data, account, account_state, thread, account_branch, shareable_theses, daily_action, day_index),
		"cooldown_reason": _dialog_cooldown_reason(account_branch, day_index)
	}


func normalize_social_state(source_state: Variant, day_index: int = 0) -> Dictionary:
	var source: Dictionary = source_state if typeof(source_state) == TYPE_DICTIONARY else {}
	var normalized: Dictionary = {
		"account_states": {},
		"post_interactions": {},
		"liked_posts": {},
		"messages": {},
		"network_contact_definitions": {},
		"dialog_state": {
			"accounts": {},
			"posts": {}
		},
		"daily_public_interactions": {
			"day_index": day_index,
			"account_action_counts": {}
		}
	}
	for account_id_value in source.get("account_states", {}).keys():
		var account_id: String = str(account_id_value)
		if account_id.is_empty() or typeof(source.get("account_states", {}).get(account_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["account_states"][account_id] = _normalize_account_state(source.get("account_states", {}).get(account_id_value, {}))
	for post_id_value in source.get("post_interactions", {}).keys():
		var post_id: String = str(post_id_value)
		if post_id.is_empty() or typeof(source.get("post_interactions", {}).get(post_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["post_interactions"][post_id] = _normalize_post_interaction(source.get("post_interactions", {}).get(post_id_value, {}))
	var liked_source: Dictionary = source.get("liked_posts", {}) if typeof(source.get("liked_posts", {})) == TYPE_DICTIONARY else {}
	for post_id_value in liked_source.keys():
		var liked_post_id: String = str(post_id_value)
		if liked_post_id.is_empty() or typeof(liked_source.get(post_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["liked_posts"][liked_post_id] = _normalize_liked_post(liked_source.get(post_id_value, {}))
	for account_id_value in source.get("messages", {}).keys():
		var account_id: String = str(account_id_value)
		if account_id.is_empty() or typeof(source.get("messages", {}).get(account_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["messages"][account_id] = _normalize_message_thread(source.get("messages", {}).get(account_id_value, {}))
	var dialog_source: Dictionary = source.get("dialog_state", {}) if typeof(source.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var normalized_dialog: Dictionary = {"accounts": {}, "posts": {}}
	for scope_id in ["accounts", "posts"]:
		var scope_rows: Dictionary = dialog_source.get(scope_id, {}) if typeof(dialog_source.get(scope_id, {})) == TYPE_DICTIONARY else {}
		for key_value in scope_rows.keys():
			var key_id: String = str(key_value)
			if key_id.is_empty() or typeof(scope_rows.get(key_value)) != TYPE_DICTIONARY:
				continue
			normalized_dialog[scope_id][key_id] = _normalize_dialog_branch(scope_rows.get(key_value, {}))
	normalized["dialog_state"] = normalized_dialog
	for contact_id_value in source.get("network_contact_definitions", {}).keys():
		var contact_id: String = str(contact_id_value)
		if contact_id.is_empty() or typeof(source.get("network_contact_definitions", {}).get(contact_id_value)) != TYPE_DICTIONARY:
			continue
		normalized["network_contact_definitions"][contact_id] = source.get("network_contact_definitions", {}).get(contact_id_value, {}).duplicate(true)
	var daily_source: Dictionary = source.get("daily_public_interactions", {}) if typeof(source.get("daily_public_interactions", {})) == TYPE_DICTIONARY else {}
	if int(daily_source.get("day_index", day_index)) == day_index:
		normalized["daily_public_interactions"] = {
			"day_index": day_index,
			"account_action_counts": daily_source.get("account_action_counts", {}).duplicate(true) if typeof(daily_source.get("account_action_counts", {})) == TYPE_DICTIONARY else {}
		}
	return normalized


func _apply_interaction(run_state, feed_data: Dictionary, snapshot: Dictionary, post: Dictionary, account_id: String, action_id: String, thesis_id: String, post_id: String, player_reply_text: String = "") -> Dictionary:
	var validation: Dictionary = validate_account_action(snapshot, account_id, action_id, thesis_id)
	if not bool(validation.get("success", false)):
		return validation
	var account: Dictionary = _account_by_id(snapshot.get("accounts", []), account_id)
	var state: Dictionary = normalize_social_state(run_state.get_twooter_social_state(), run_state.day_index)
	var account_states: Dictionary = state.get("account_states", {})
	var account_state: Dictionary = _account_state(account_states, account_id)
	var action_def: Dictionary = ACTION_DEFINITIONS.get(action_id, {})
	var is_private: bool = bool(action_def.get("private", false))
	var thesis: Dictionary = _thesis_by_id(snapshot.get("shareable_theses", []), thesis_id)
	var branch_scope: String = "accounts" if is_private else "posts"
	var branch_key: String = account_id if is_private else post_id
	var branch_tree_id: String = _select_message_tree_id(feed_data, account, account_state, state.get("messages", {}).get(account_id, {}), snapshot.get("shareable_theses", [])) if is_private else _select_public_tree_id(feed_data, account, account_state, post)
	var dialog_branch: Dictionary = _dialog_branch(state, branch_scope, branch_key, branch_tree_id, feed_data)
	var dialog_selection: Dictionary = _resolve_dialog_selection(
		feed_data,
		account,
		account_state,
		post,
		snapshot.get("shareable_theses", []),
		dialog_branch,
		is_private,
		action_id,
		thesis_id,
		player_reply_text,
		run_state.day_index
	)
	if not str(dialog_selection.get("blocked_reason", "")).is_empty():
		return {
			"success": false,
			"message": str(dialog_selection.get("message", "That conversation needs another step first.")),
			"blocked_reason": str(dialog_selection.get("blocked_reason", ""))
		}
	var selected_dialog_row: Dictionary = dialog_selection.get("row", {}) if typeof(dialog_selection.get("row", {})) == TYPE_DICTIONARY else {}
	var resolved_player_text: String = player_reply_text.strip_edges()
	if resolved_player_text.is_empty() and not selected_dialog_row.is_empty():
		resolved_player_text = str(selected_dialog_row.get("player_text", "")).strip_edges()
	var next_repeat_count: int = _dialog_next_repeat_count(dialog_branch, str(dialog_selection.get("option_id", action_id)), action_id, run_state.day_index)
	var soft_cooldown: bool = next_repeat_count >= 2
	var gain_multiplier: float = _social_gain_multiplier(state, account_id, action_id, is_private, run_state.day_index)
	var already_connected: bool = action_id == "connect" and _is_social_contact_connected(run_state, account, account_state)
	if already_connected:
		gain_multiplier = 0.0
	_increment_social_daily_count(state, account_id, action_id, is_private, run_state.day_index)
	if soft_cooldown:
		gain_multiplier = 0.0
	var relationship_delta: int = int(round(float(action_def.get("relationship_delta", 0)) * gain_multiplier))
	var exposure_delta: int = int(round(float(action_def.get("exposure_delta", 0)) * gain_multiplier))
	var credibility_delta: int = int(round(float(action_def.get("credibility_delta", 0)) * gain_multiplier))
	if action_id == "share_thesis" and not thesis.is_empty() and not soft_cooldown:
		credibility_delta += _thesis_credibility_bonus(thesis)
	var unfollowed_attention_nudge: bool = false
	if _is_attention_ask_action(action_id) and not bool(account_state.get("following", false)):
		account_state["unfollowed_ask_count"] = max(int(account_state.get("unfollowed_ask_count", 0)) + 1, 0)
		account_state["last_unfollowed_ask_day_index"] = run_state.day_index
		unfollowed_attention_nudge = int(account_state.get("unfollowed_ask_count", 0)) >= 2
	elif bool(account_state.get("following", false)):
		account_state["unfollowed_ask_count"] = 0
	if action_id == "connect":
		account_state["connected"] = true
	account_state["relationship"] = clampi(int(account_state.get("relationship", 0)) + relationship_delta, 0, 100)
	account_state["exposure"] = clampi(int(account_state.get("exposure", 0)) + exposure_delta, 0, 100)
	account_state["credibility"] = clampi(int(account_state.get("credibility", 0)) + credibility_delta, 0, 100)
	account_state["importance"] = _importance_score(account_state)
	account_state["last_interaction_day_index"] = run_state.day_index
	account_state["interaction_count"] = int(account_state.get("interaction_count", 0)) + 1
	account_state["relationship_stage"] = _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	account_states[account_id] = account_state
	state["account_states"] = account_states

	var reply_text: String = ""
	if soft_cooldown:
		reply_text = _dialog_cooldown_reply_text(account, dialog_selection, run_state.day_index)
	elif _should_correct_no_post_reference(account, resolved_player_text):
		reply_text = _no_post_self_aware_reply_text(account, post, thesis, account_state, dialog_selection, run_state.day_index)
	elif unfollowed_attention_nudge:
		reply_text = _unfollowed_ask_reply_text(account, post, thesis, account_state, dialog_selection, run_state.day_index)
	else:
		reply_text = _dialog_reply_text(feed_data, account, post, account_state, thesis, dialog_selection, run_state.day_index)
	if already_connected:
		reply_text = _already_connected_reply_text(account, run_state.day_index)
	elif is_private and not soft_cooldown:
		reply_text = _private_same_day_reply_text(reply_text, gain_multiplier, account, post, thesis, run_state.day_index)
	if reply_text.is_empty():
		reply_text = _reply_text(feed_data, account, post, account_state, action_id, thesis, run_state.day_index, gain_multiplier)
	if not post_id.is_empty():
		_record_post_reply(state, post_id, account_id, action_id, player_reply_text, reply_text, run_state.day_index, relationship_delta, exposure_delta, credibility_delta, account_state)
	if is_private:
		if resolved_player_text.is_empty():
			resolved_player_text = _player_message_text(action_id, thesis, post)
		_record_message_row(state, account, action_id, resolved_player_text, reply_text, run_state.day_index)
	_record_timeline_row(state, account_id, action_id, reply_text, post_id, run_state.day_index)
	_record_dialog_branch_progress(state, branch_scope, branch_key, dialog_branch, dialog_selection, next_repeat_count, soft_cooldown, run_state.day_index)
	var network_result: Dictionary = _apply_network_bridge(run_state, state, account, account_state, post, action_id, thesis, reply_text)
	run_state.set_twooter_social_state(state)
	return {
		"success": true,
		"message": reply_text,
		"reply_text": reply_text,
		"account_state": account_state.duplicate(true),
		"relationship_delta": relationship_delta,
		"exposure_delta": exposure_delta,
		"credibility_delta": credibility_delta,
		"private": is_private,
		"player_text": resolved_player_text,
		"network_changed": bool(network_result.get("network_changed", false)),
		"network_result": network_result
	}


func _apply_account_social_fields(account: Dictionary, account_state: Dictionary, message_thread: Dictionary) -> void:
	account["relationship"] = int(account_state.get("relationship", 0))
	account["exposure"] = int(account_state.get("exposure", 0))
	account["credibility"] = int(account_state.get("credibility", 0))
	account["importance"] = int(account_state.get("importance", 0))
	account["following"] = bool(account_state.get("following", false))
	account["connected"] = bool(account_state.get("connected", false))
	account["likes_given"] = int(account_state.get("likes_given", 0))
	account["like_relationship_progress"] = float(account_state.get("like_relationship_progress", 0.0))
	account["unfollowed_ask_count"] = int(account_state.get("unfollowed_ask_count", 0))
	account["relationship_stage"] = _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	account["interaction_count"] = int(account_state.get("interaction_count", 0))
	account["timeline"] = account_state.get("timeline", []).duplicate(true) if typeof(account_state.get("timeline", [])) == TYPE_ARRAY else []
	account["unread_count"] = int(message_thread.get("unread_count", 0)) if typeof(message_thread) == TYPE_DICTIONARY else 0
	account["social_contact_id"] = _social_contact_id(account)


func _dialog_trees(feed_data: Dictionary) -> Dictionary:
	var source: Dictionary = feed_data.get("dialog_trees", {}) if typeof(feed_data.get("dialog_trees", {})) == TYPE_DICTIONARY else {}
	if source.is_empty():
		return DEFAULT_DIALOG_TREES
	return source


func _dialog_tree(feed_data: Dictionary, tree_id: String) -> Dictionary:
	var trees: Dictionary = _dialog_trees(feed_data)
	var tree: Dictionary = trees.get(tree_id, {}) if typeof(trees.get(tree_id, {})) == TYPE_DICTIONARY else {}
	if tree.is_empty():
		tree = trees.get("clean_intro", {}) if typeof(trees.get("clean_intro", {})) == TYPE_DICTIONARY else {}
	return tree


func _dialog_node(tree: Dictionary, node_id: String) -> Dictionary:
	var nodes: Dictionary = tree.get("nodes", {}) if typeof(tree.get("nodes", {})) == TYPE_DICTIONARY else {}
	var resolved_node_id: String = node_id
	if resolved_node_id.is_empty() or not nodes.has(resolved_node_id):
		resolved_node_id = str(tree.get("entry_node", ""))
	return nodes.get(resolved_node_id, {}) if typeof(nodes.get(resolved_node_id, {})) == TYPE_DICTIONARY else {}


func _dialog_branch(state: Dictionary, scope: String, key_id: String, fallback_tree_id: String, feed_data: Dictionary) -> Dictionary:
	var dialog_state: Dictionary = state.get("dialog_state", {}) if typeof(state.get("dialog_state", {})) == TYPE_DICTIONARY else {}
	var scope_rows: Dictionary = dialog_state.get(scope, {}) if typeof(dialog_state.get(scope, {})) == TYPE_DICTIONARY else {}
	var branch: Dictionary = _normalize_dialog_branch(scope_rows.get(key_id, {}))
	var tree_id: String = str(branch.get("tree_id", ""))
	if tree_id.is_empty():
		tree_id = fallback_tree_id
	var tree: Dictionary = _dialog_tree(feed_data, tree_id)
	if tree.is_empty():
		tree_id = "clean_intro"
		tree = _dialog_tree(feed_data, tree_id)
	branch["tree_id"] = tree_id
	if str(branch.get("node_id", "")).is_empty():
		branch["node_id"] = str(tree.get("entry_node", ""))
	return branch


func _dialog_cooldown_reason(branch: Dictionary, day_index: int) -> String:
	if int(branch.get("cooldown_until_day", -1)) >= day_index:
		var reason: String = str(branch.get("cooldown_reason", "soft_cooldown"))
		return reason if not reason.is_empty() else "soft_cooldown"
	return ""


func _select_public_tree_id(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, post: Dictionary) -> String:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var preferred_tree_id: String = _profile_preferred_tree_id(feed_data, profile, false)
	if not preferred_tree_id.is_empty():
		return preferred_tree_id
	var category: String = str(post.get("category", "")).to_lower()
	if category.contains("source") or category.contains("rumor") or category.contains("corporate"):
		return "source_check"
	if int(account_state.get("relationship", 0)) >= 18:
		return "trust_building"
	return "market_read"


func _select_message_tree_id(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, thread: Dictionary, shareable_theses: Array) -> String:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var is_network_source: bool = bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact"
	if is_network_source:
		var preferred_network_tree_id: String = _profile_preferred_tree_id(feed_data, profile, true)
		if not preferred_network_tree_id.is_empty():
			return preferred_network_tree_id
	if str(profile.get("risk_profile", "")) == "suspicious":
		return "suspicious_boundary"
	var stage: String = _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	if stage in ["trusted", "inner_circle_candidate"]:
		return "event_invite"
	if int(account_state.get("relationship", 0)) < 5:
		return "clean_intro"
	if int(account_state.get("credibility", 0)) < 12:
		return "thesis_review"
	var rows: Array = thread.get("rows", []) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []
	if rows.size() >= 4 or int(account_state.get("relationship", 0)) >= 18:
		return "trust_building"
	if int(account_state.get("credibility", 0)) < 8:
		return "source_check"
	var preferred_tree_id: String = _profile_preferred_tree_id(feed_data, profile, true)
	if not preferred_tree_id.is_empty():
		return preferred_tree_id
	return "clean_intro"


func _profile_preferred_tree_id(feed_data: Dictionary, profile: Dictionary, is_private: bool) -> String:
	var trees: Array = profile.get("dialog_trees", []) if typeof(profile.get("dialog_trees", [])) == TYPE_ARRAY else []
	for tree_value in trees:
		var tree_id: String = str(tree_value)
		if _tree_has_surface(feed_data, tree_id, is_private):
			return tree_id
	return ""


func _tree_has_surface(feed_data: Dictionary, tree_id: String, is_private: bool) -> bool:
	var tree: Dictionary = _dialog_tree(feed_data, tree_id)
	var nodes: Dictionary = tree.get("nodes", {}) if typeof(tree.get("nodes", {})) == TYPE_DICTIONARY else {}
	for node_value in nodes.values():
		if typeof(node_value) != TYPE_DICTIONARY:
			continue
		for option_value in node_value.get("options", []):
			if typeof(option_value) == TYPE_DICTIONARY and not _dialog_option_action_id(option_value, is_private).is_empty():
				return true
	return false


func _tree_dialog_options(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, post: Dictionary, thesis_rows: Array, branch: Dictionary, is_private: bool, day_index: int, daily_action: Dictionary = {}) -> Array:
	if not _dialog_cooldown_reason(branch, day_index).is_empty():
		return []
	var tree_id: String = str(branch.get("tree_id", "clean_intro"))
	var tree: Dictionary = _dialog_tree(feed_data, tree_id)
	var node_id: String = str(branch.get("node_id", tree.get("entry_node", "")))
	var node: Dictionary = _dialog_node(tree, node_id)
	if node.is_empty():
		return []
	var thesis: Dictionary = {}
	if not thesis_rows.is_empty() and typeof(thesis_rows[0]) == TYPE_DICTIONARY:
		thesis = thesis_rows[0]
	var rows: Array = []
	var context: Dictionary = _dialog_context(account, account_state, post, thesis)
	for option_value in node.get("options", []):
		if rows.size() >= 3 or typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_value
		var action_id: String = _dialog_option_action_id(option, is_private)
		if action_id.is_empty() or not ACTION_DEFINITIONS.has(action_id):
			continue
		var player_lines: Array = option.get("player_lines", []) if typeof(option.get("player_lines", [])) == TYPE_ARRAY else []
		var block_reason: String = _dialog_option_block_reason(option, action_id, account_state, thesis, is_private, daily_action)
		var player_text: String = ""
		if block_reason.is_empty():
			player_text = _render_dialog_pool(player_lines, context, "%s|%s|%s|%d" % [str(account.get("id", "")), tree_id, str(option.get("id", "")), day_index])
		else:
			player_text = _dialog_option_blocked_text(option, action_id, block_reason, context, "%s|%s|%s|blocked|%d" % [str(account.get("id", "")), tree_id, str(option.get("id", "")), day_index])
		player_text = _self_aware_player_text(account, player_text, "%s|%s|%s|self-aware|%d" % [str(account.get("id", "")), tree_id, str(option.get("id", "")), day_index])
		rows.append({
			"id": action_id,
			"label": str(option.get("label", ACTION_DEFINITIONS.get(action_id, {}).get("label", action_id.capitalize()))),
			"tree_id": tree_id,
			"node_id": node_id,
			"option_id": str(option.get("id", action_id)),
			"action_id": action_id,
			"player_text": player_text,
			"thesis_id": str(thesis.get("id", "")) if action_id == "share_thesis" else "",
			"cost_ap": 1 if is_private else 0,
			"enabled": block_reason.is_empty(),
			"cooldown_reason": "",
			"blocked_reason": block_reason
		})
	return rows


func _dialog_option_block_reason(option: Dictionary, action_id: String, account_state: Dictionary, thesis: Dictionary, is_private: bool, daily_action: Dictionary = {}) -> String:
	var requirements: Dictionary = option.get("requirements", {}) if typeof(option.get("requirements", {})) == TYPE_DICTIONARY else {}
	if action_id == "share_thesis" or bool(requirements.get("shareable_thesis", false)):
		if thesis.is_empty():
			return "missing_thesis"
	if requirements.has("min_relationship") and int(account_state.get("relationship", 0)) < int(requirements.get("min_relationship", 0)):
		return "relationship"
	if requirements.has("min_credibility") and int(account_state.get("credibility", 0)) < int(requirements.get("min_credibility", 0)):
		return "credibility"
	if requirements.has("min_importance") and int(account_state.get("importance", 0)) < int(requirements.get("min_importance", 0)):
		return "importance"
	var required_stage: String = str(requirements.get("relationship_stage", "")).strip_edges()
	if not required_stage.is_empty() and not _relationship_stage_meets(str(account_state.get("relationship_stage", "stranger")), required_stage):
		return "relationship_stage"
	if is_private and int(requirements.get("daily_ap", 1)) > 0 and not daily_action.is_empty():
		if int(daily_action.get("remaining", 0)) < int(requirements.get("daily_ap", 1)):
			return "daily_ap"
	return ""


func _dialog_option_blocked_text(option: Dictionary, action_id: String, block_reason: String, context: Dictionary, seed: String) -> String:
	var blocked_lines: Array = option.get("blocked_lines", []) if typeof(option.get("blocked_lines", [])) == TYPE_ARRAY else []
	if blocked_lines.is_empty():
		blocked_lines = _default_dialog_blocked_lines(action_id, block_reason)
	return _render_dialog_pool(blocked_lines, context, seed)


func _default_dialog_blocked_lines(action_id: String, block_reason: String) -> Array:
	match block_reason:
		"missing_thesis":
			return [
				"Build your thesis first; then I can respond to something concrete.",
				"Write the thesis first. I need assumptions, evidence, and an invalidation point."
			]
		"relationship", "relationship_stage":
			if action_id == "accept_invite":
				return [
					"Build more trust first. Rooms open after your questions prove useful.",
					"Not yet. Keep showing clean work before asking for access."
				]
			return [
				"Build more relationship first. The next ask needs more trust.",
				"Not yet. Keep the conversation useful before pushing further."
			]
		"credibility":
			return [
				"Build credibility first. Bring cleaner evidence before asking for more.",
				"Not yet. Show the work before asking for a deeper read."
			]
		"importance":
			return [
				"Become more important to the conversation first. Useful work opens the next door.",
				"Not yet. Make your reads matter before asking for more access."
			]
		"daily_ap":
			return [
				"You need 1 AP today to send this. Come back after you free up time.",
				"No AP left for this today. Advance the day before pushing the conversation."
			]
	return [
		"Something is missing first. Build the prerequisite before continuing.",
		"Not yet. Bring the missing piece before asking again."
	]


func _relationship_stage_meets(current_stage: String, required_stage: String) -> bool:
	var stage_order: Dictionary = {
		"stranger": 0,
		"familiar": 1,
		"trusted": 2,
		"inner_circle_candidate": 3
	}
	return int(stage_order.get(current_stage, 0)) >= int(stage_order.get(required_stage, 0))


func _dialog_option_action_id(option: Dictionary, is_private: bool) -> String:
	var key: String = "private_action_id" if is_private else "public_action_id"
	var action_id: String = str(option.get(key, ""))
	if action_id.is_empty():
		action_id = str(option.get("action_id", ""))
	if is_private and not PRIVATE_ACTION_IDS.has(action_id):
		return ""
	if not is_private and not PUBLIC_ACTION_IDS.has(action_id):
		return ""
	return action_id


func _resolve_dialog_selection(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, post: Dictionary, thesis_rows: Array, branch: Dictionary, is_private: bool, action_id: String, thesis_id: String, player_text: String, day_index: int) -> Dictionary:
	var cooldown_reason: String = _dialog_cooldown_reason(branch, day_index)
	if not cooldown_reason.is_empty():
		return {
			"found": false,
			"blocked_reason": cooldown_reason,
			"message": _dialog_cooldown_reply_text(account, {"option_id": action_id}, day_index),
			"option_id": action_id,
			"next_node": "",
			"account_replies": []
		}
	var rows: Array = _tree_dialog_options(feed_data, account, account_state, post, thesis_rows, branch, is_private, day_index)
	var selected_row: Dictionary = {}
	var blocked_row: Dictionary = {}
	for row_value in rows:
		if typeof(row_value) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_value
		if str(row.get("action_id", row.get("id", ""))) != action_id:
			continue
		if not bool(row.get("enabled", true)):
			blocked_row = row
			continue
		if not thesis_id.is_empty() and str(row.get("thesis_id", "")) != thesis_id:
			continue
		if not player_text.strip_edges().is_empty() and str(row.get("player_text", "")) != player_text.strip_edges():
			continue
		selected_row = row
		break
	if selected_row.is_empty():
		for row_value in rows:
			if typeof(row_value) == TYPE_DICTIONARY and bool(row_value.get("enabled", true)) and str(row_value.get("action_id", row_value.get("id", ""))) == action_id:
				selected_row = row_value
				break
	if selected_row.is_empty() and not blocked_row.is_empty():
		return {
			"found": false,
			"blocked_reason": str(blocked_row.get("blocked_reason", "requirement")),
			"message": str(blocked_row.get("player_text", "That conversation needs another step first.")),
			"option_id": str(blocked_row.get("option_id", action_id)),
			"next_node": "",
			"account_replies": [],
			"row": blocked_row
		}
	if selected_row.is_empty():
		return {"found": false, "option_id": action_id, "next_node": "", "account_replies": []}
	var tree: Dictionary = _dialog_tree(feed_data, str(selected_row.get("tree_id", "")))
	var node: Dictionary = _dialog_node(tree, str(selected_row.get("node_id", "")))
	var raw_option: Dictionary = _raw_dialog_option(node, str(selected_row.get("option_id", "")))
	return {
		"found": true,
		"tree_id": str(selected_row.get("tree_id", "")),
		"node_id": str(selected_row.get("node_id", "")),
		"option_id": str(selected_row.get("option_id", "")),
		"next_node": str(raw_option.get("next_node", selected_row.get("node_id", ""))),
		"account_replies": node.get("account_replies", []) if typeof(node.get("account_replies", [])) == TYPE_ARRAY else [],
		"outcome": str(raw_option.get("outcome", "")),
		"row": selected_row
	}


func _raw_dialog_option(node: Dictionary, option_id: String) -> Dictionary:
	for option_value in node.get("options", []):
		if typeof(option_value) == TYPE_DICTIONARY and str(option_value.get("id", "")) == option_id:
			return option_value
	return {}


func _dialog_next_repeat_count(branch: Dictionary, option_id: String, action_id: String, day_index: int) -> int:
	if option_id.is_empty() and action_id.is_empty():
		return 0
	var same_day: bool = int(branch.get("last_day_index", -1)) == day_index
	var repeated_option: bool = not option_id.is_empty() and str(branch.get("last_option_id", "")) == option_id
	var repeated_action: bool = not action_id.is_empty() and str(branch.get("last_action_id", "")) == action_id
	if same_day and (repeated_option or repeated_action):
		return int(branch.get("repeat_count", 0)) + 1
	return 0


func _dialog_reply_text(feed_data: Dictionary, account: Dictionary, post: Dictionary, account_state: Dictionary, thesis: Dictionary, selection: Dictionary, day_index: int) -> String:
	if not bool(selection.get("found", false)):
		return ""
	var pool: Array = selection.get("account_replies", []) if typeof(selection.get("account_replies", [])) == TYPE_ARRAY else []
	pool = _relationship_dialog_reply_pool(pool, account, account_state, feed_data)
	var context: Dictionary = _dialog_context(account, account_state, post, thesis)
	var seed: String = "%s|%s|%s|%s|%d|%d" % [
		str(account.get("id", "")),
		str(selection.get("tree_id", "")),
		str(selection.get("node_id", "")),
		str(selection.get("option_id", "")),
		day_index,
		int(account_state.get("interaction_count", 0))
	]
	return _render_dialog_pool(pool, context, seed)


func _relationship_dialog_reply_pool(base_pool: Array, account: Dictionary, account_state: Dictionary, feed_data: Dictionary = {}) -> Array:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var relationship: int = int(account_state.get("relationship", 0))
	var stage: String = _relationship_stage(relationship, int(account_state.get("credibility", 0)), int(account_state.get("importance", 0)))
	var tuned_pool: Array = base_pool.duplicate()
	if bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact":
		if relationship >= 8:
			tuned_pool.append_array(_stage_reply_pool(feed_data, "network_source_reply_pools", "familiar", NETWORK_SOURCE_DIALOG_REPLY_POOLS))
		if stage in ["trusted", "inner_circle_candidate"]:
			tuned_pool.append_array(_stage_reply_pool(feed_data, "network_source_reply_pools", "trusted", NETWORK_SOURCE_DIALOG_REPLY_POOLS))
		if stage == "inner_circle_candidate":
			tuned_pool.append_array(_stage_reply_pool(feed_data, "network_source_reply_pools", "inner_circle_candidate", NETWORK_SOURCE_DIALOG_REPLY_POOLS))
		return tuned_pool
	if relationship >= 8:
		tuned_pool.append_array(_stage_reply_pool(feed_data, "relationship_reply_pools", "familiar", RELATIONSHIP_DIALOG_REPLY_POOLS))
	if stage in ["trusted", "inner_circle_candidate"]:
		tuned_pool.append_array(_stage_reply_pool(feed_data, "relationship_reply_pools", "trusted", RELATIONSHIP_DIALOG_REPLY_POOLS))
	if stage == "inner_circle_candidate":
		tuned_pool.append_array(_stage_reply_pool(feed_data, "relationship_reply_pools", "inner_circle_candidate", RELATIONSHIP_DIALOG_REPLY_POOLS))
	return tuned_pool


func _stage_reply_pool(feed_data: Dictionary, pool_key: String, stage: String, fallback_pools: Dictionary) -> Array:
	var rows: Array = []
	rows.append_array(fallback_pools.get(stage, []))
	var data_pools: Dictionary = feed_data.get(pool_key, {}) if typeof(feed_data.get(pool_key, {})) == TYPE_DICTIONARY else {}
	var data_rows: Array = data_pools.get(stage, []) if typeof(data_pools.get(stage, [])) == TYPE_ARRAY else []
	rows.append_array(_clean_string_pool(data_rows))
	return rows


func _is_attention_ask_action(action_id: String) -> bool:
	return ATTENTION_ASK_ACTION_IDS.has(action_id)


func _unfollowed_ask_reply_text(account: Dictionary, post: Dictionary, thesis: Dictionary, account_state: Dictionary, selection: Dictionary, day_index: int) -> String:
	var context: Dictionary = _dialog_context(account, account_state, post, thesis)
	var seed: String = "%s|%s|%s|unfollowed|%d|%d" % [
		str(account.get("id", "")),
		str(selection.get("tree_id", "")),
		str(selection.get("option_id", "")),
		day_index,
		int(account_state.get("unfollowed_ask_count", 0))
	]
	return _render_dialog_pool(UNFOLLOWED_ASK_REPLY_POOL, context, seed)


func _dialog_cooldown_reply_text(account: Dictionary, selection: Dictionary, day_index: int) -> String:
	var pool: Array = [
		"We are circling the same point. Wait for new tape or bring a sharper thesis.",
		"You asked this angle already. Pause for now and come back with evidence.",
		"Same question, same answer. Bring a source, a thesis, or fresh market context next time."
	]
	var context: Dictionary = {"account_name": str(account.get("display_name", "Account"))}
	return _render_dialog_pool(pool, context, "%s|%s|%d" % [str(account.get("id", "")), str(selection.get("option_id", "")), day_index])


func _no_post_self_aware_reply_text(account: Dictionary, post: Dictionary, thesis: Dictionary, account_state: Dictionary, selection: Dictionary, day_index: int) -> String:
	var pool: Array = [
		"I have not posted anything here yet, so do not praise imaginary posts. Ask me about the lead or bring a source.",
		"Zero public posts from me so far. If you want a useful read, start with the actual lead.",
		"I have not posted a public note here. Useful conversation starts with the source in front of us.",
		"Odd compliment. I have no public posts here yet, so keep the question tied to what you can verify."
	]
	var context: Dictionary = _dialog_context(account, account_state, post, thesis)
	return _render_dialog_pool(pool, context, "%s|%s|no_posts|%d|%d" % [
		str(account.get("id", "")),
		str(selection.get("option_id", "")),
		day_index,
		int(account_state.get("interaction_count", 0))
	])


func _record_dialog_branch_progress(state: Dictionary, scope: String, key_id: String, branch: Dictionary, selection: Dictionary, repeat_count: int, soft_cooldown: bool, day_index: int) -> void:
	if key_id.is_empty() or not bool(selection.get("found", false)):
		return
	var dialog_state: Dictionary = state.get("dialog_state", {}) if typeof(state.get("dialog_state", {})) == TYPE_DICTIONARY else {"accounts": {}, "posts": {}}
	if typeof(dialog_state.get("accounts", {})) != TYPE_DICTIONARY:
		dialog_state["accounts"] = {}
	if typeof(dialog_state.get("posts", {})) != TYPE_DICTIONARY:
		dialog_state["posts"] = {}
	var scope_rows: Dictionary = dialog_state.get(scope, {})
	var next_branch: Dictionary = _normalize_dialog_branch(branch)
	next_branch["tree_id"] = str(selection.get("tree_id", next_branch.get("tree_id", "")))
	next_branch["node_id"] = str(selection.get("next_node", next_branch.get("node_id", "")))
	next_branch["last_option_id"] = str(selection.get("option_id", ""))
	var selected_row: Dictionary = selection.get("row", {}) if typeof(selection.get("row", {})) == TYPE_DICTIONARY else {}
	next_branch["last_action_id"] = str(selected_row.get("action_id", ""))
	next_branch["repeat_count"] = repeat_count
	next_branch["last_day_index"] = day_index
	next_branch["step_count"] = int(next_branch.get("step_count", 0)) + 1
	if soft_cooldown:
		next_branch["cooldown_until_day"] = day_index
		next_branch["cooldown_reason"] = "soft_cooldown"
	else:
		next_branch["cooldown_until_day"] = -1
		next_branch["cooldown_reason"] = ""
	scope_rows[key_id] = next_branch
	dialog_state[scope] = scope_rows
	state["dialog_state"] = dialog_state


func _dialog_context(account: Dictionary, account_state: Dictionary, post: Dictionary, thesis: Dictionary) -> Dictionary:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var is_network_source: bool = bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact"
	var ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = str(thesis.get("ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = str(profile.get("target_ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = "this lead" if is_network_source else "the setup"
	var company: String = str(post.get("target_company_name", "")).strip_edges()
	if company.is_empty():
		company = str(thesis.get("company_name", "")).strip_edges()
	if company.is_empty():
		company = str(profile.get("target_company_name", "")).strip_edges()
	if company.is_empty():
		company = ticker
	return {
		"account_name": str(account.get("display_name", "Account")),
		"handle": str(account.get("handle", "")),
		"ticker": ticker,
		"company": company,
		"thesis_title": str(thesis.get("title", "my thesis")),
		"stage": str(account_state.get("relationship_stage", "stranger")),
		"relationship": str(account_state.get("relationship", 0)),
		"likes_given": str(account_state.get("likes_given", 0)),
		"public_post_count": str(_account_public_post_count(account))
	}


func _render_dialog_pool(pool: Array, context: Dictionary, seed: String) -> String:
	var clean_pool: Array = _clean_string_pool(pool)
	if clean_pool.is_empty():
		return "I want to keep this clean and evidence-first."
	return _render_template(str(clean_pool[int(abs(hash(seed))) % clean_pool.size()]), context)


func _self_aware_player_text(account: Dictionary, player_text: String, seed: String) -> String:
	if not _should_correct_no_post_reference(account, player_text):
		return player_text
	var pool: Array = [
		"I found you through this lead, not through your posts. Can we compare notes without turning it into a shortcut?",
		"You do not have public posts here yet, so I want to ask about the lead directly and keep it evidence-first.",
		"I have not seen public posts from you here. Can we start with what can actually be verified?"
	]
	return _render_dialog_pool(pool, _dialog_context(account, {}, {}, {}), seed)


func _should_correct_no_post_reference(account: Dictionary, text: String) -> bool:
	if _account_public_post_count(account) > 0:
		return false
	return _text_references_account_posts(text)


func _text_references_account_posts(text: String) -> bool:
	var clean_text: String = text.strip_edges().to_lower()
	if clean_text.is_empty():
		return false
	return clean_text.contains("your posts") or clean_text.contains("your post") or clean_text.contains("your twoots") or clean_text.contains("your twoot")


func _account_public_post_count(account: Dictionary) -> int:
	if account.has("public_post_count"):
		return max(int(account.get("public_post_count", 0)), 0)
	if bool(account.get("has_public_posts", false)):
		return 1
	return 0


func _post_interaction_options(post: Dictionary, _account_state: Dictionary, _daily_action: Dictionary, _thesis_rows: Array, day_index: int, interaction: Dictionary) -> Array:
	if bool(interaction.get("concluded", false)) or int(interaction.get("conversation_step", 0)) >= PUBLIC_CHAIN_MAX_STEP:
		return []
	if PUBLIC_ACTION_IDS.is_empty():
		return []
	return [{
		"id": "reply",
		"label": "Reply",
		"detail": "Open reply composer",
		"cost_ap": 0,
		"private": false,
		"dialog": true,
		"diminished": int(interaction.get("last_day_index", -1)) == day_index and int(interaction.get("interaction_count", 0)) > 0
	}]


func _reply_dialog_options(feed_data: Dictionary, post: Dictionary, account: Dictionary, account_state: Dictionary, interaction: Dictionary, branch: Dictionary, thesis_rows: Array, daily_action: Dictionary, day_index: int) -> Array:
	if bool(interaction.get("concluded", false)) or int(interaction.get("conversation_step", 0)) >= PUBLIC_CHAIN_MAX_STEP:
		return []
	if not _dialog_cooldown_reason(branch, day_index).is_empty():
		return []
	var tree_rows: Array = _tree_dialog_options(feed_data, account, account_state, post, thesis_rows, branch, false, day_index, daily_action)
	if not tree_rows.is_empty():
		return tree_rows
	var options: Array = []
	for action_id in PUBLIC_ACTION_IDS:
		var action_def: Dictionary = ACTION_DEFINITIONS.get(action_id, {})
		var daily_key: String = "%s|%s" % [str(post.get("account_id", "")), action_id]
		options.append({
			"id": action_id,
			"label": str(action_def.get("label", action_id.capitalize())),
			"player_text": _player_public_reply_text(account, post, action_id, int(interaction.get("conversation_step", 0)), day_index),
			"detail": str(action_def.get("detail", "")),
			"cost_ap": 0,
			"private": false,
			"diminished": int(interaction.get("last_day_index", -1)) == day_index and int(interaction.get("interaction_count", 0)) > 0,
			"daily_key": daily_key
		})
	return options


func _public_gain_multiplier(state: Dictionary, account_id: String, action_id: String, day_index: int) -> float:
	var count: int = _daily_social_action_count(state, account_id, action_id, day_index)
	if count <= 0:
		return 1.0
	if count == 1:
		return 0.35
	return 0.0


func _private_gain_multiplier(state: Dictionary, account_id: String, action_id: String, day_index: int) -> float:
	var same_action_count: int = _daily_social_action_count(state, account_id, action_id, day_index)
	if same_action_count > 0:
		return 0.0
	var private_count: int = _daily_social_action_count(state, account_id, "private", day_index)
	if private_count <= 0:
		return 1.0
	if private_count == 1:
		return 0.35
	return 0.0


func _social_gain_multiplier(state: Dictionary, account_id: String, action_id: String, is_private: bool, day_index: int) -> float:
	if is_private:
		return _private_gain_multiplier(state, account_id, action_id, day_index)
	return _public_gain_multiplier(state, account_id, action_id, day_index)


func _daily_social_action_count(state: Dictionary, account_id: String, action_id: String, day_index: int) -> int:
	var daily: Dictionary = state.get("daily_public_interactions", {})
	if int(daily.get("day_index", day_index)) != day_index:
		return 0
	var counts: Dictionary = daily.get("account_action_counts", {}) if typeof(daily.get("account_action_counts", {})) == TYPE_DICTIONARY else {}
	return int(counts.get("%s|%s" % [account_id, action_id], 0))


func _like_exposure_delta(state: Dictionary, account_id: String, day_index: int) -> int:
	if _daily_social_action_count(state, account_id, "like", day_index) <= 0:
		return 1
	return 0


func _like_relationship_progress_delta(state: Dictionary, account_id: String, day_index: int) -> float:
	var same_day_likes: int = _daily_social_action_count(state, account_id, "like", day_index)
	if same_day_likes <= 0:
		return LIKE_RELATIONSHIP_PROGRESS
	if same_day_likes == 1:
		return SAME_DAY_SECOND_LIKE_RELATIONSHIP_PROGRESS
	return 0.0


func _increment_public_daily_count(state: Dictionary, account_id: String, action_id: String, day_index: int) -> void:
	_increment_social_daily_count(state, account_id, action_id, false, day_index)


func _increment_social_daily_count(state: Dictionary, account_id: String, action_id: String, is_private: bool, day_index: int) -> void:
	var daily: Dictionary = state.get("daily_public_interactions", {})
	if int(daily.get("day_index", day_index)) != day_index:
		daily = {"day_index": day_index, "account_action_counts": {}}
	var counts: Dictionary = daily.get("account_action_counts", {})
	var key: String = "%s|%s" % [account_id, action_id]
	counts[key] = int(counts.get(key, 0)) + 1
	if is_private:
		var private_key: String = "%s|private" % account_id
		counts[private_key] = int(counts.get(private_key, 0)) + 1
	daily["account_action_counts"] = counts
	state["daily_public_interactions"] = daily


func _liked_post_memory_text(post: Dictionary) -> String:
	var ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
	if not ticker.is_empty():
		return "Liked a post about $%s." % ticker
	var topic: String = _public_topic_text(post)
	if not topic.is_empty():
		return "Liked a post about %s." % topic
	return "Liked a Twooter post."


func _record_post_reply(state: Dictionary, post_id: String, account_id: String, action_id: String, player_text: String, reply_text: String, day_index: int, relationship_delta: int, exposure_delta: int, credibility_delta: int, account_state: Dictionary) -> void:
	var post_interactions: Dictionary = state.get("post_interactions", {})
	var interaction: Dictionary = _normalize_post_interaction(post_interactions.get(post_id, {}))
	var replies: Array = interaction.get("replies", [])
	replies.append({
		"account_id": account_id,
		"action_id": action_id,
		"player_text": player_text,
		"reply_text": reply_text,
		"day_index": day_index,
		"relationship_delta": relationship_delta,
		"exposure_delta": exposure_delta,
		"credibility_delta": credibility_delta
	})
	if replies.size() > MAX_PUBLIC_REPLY_ROWS_PER_POST:
		replies = replies.slice(replies.size() - MAX_PUBLIC_REPLY_ROWS_PER_POST, replies.size())
	interaction["replies"] = replies
	interaction["interaction_count"] = int(interaction.get("interaction_count", 0)) + 1
	interaction["last_day_index"] = day_index
	var next_step: int = int(interaction.get("conversation_step", 0)) + 1
	interaction["conversation_step"] = next_step
	var conclusion: Dictionary = _public_conversation_conclusion(next_step, account_state)
	if bool(conclusion.get("concluded", false)):
		interaction["concluded"] = true
		interaction["conclusion_reason"] = str(conclusion.get("reason", ""))
		interaction["followup_unlocked"] = bool(conclusion.get("followup_unlocked", false))
	post_interactions[post_id] = interaction
	state["post_interactions"] = post_interactions


func _record_message_row(state: Dictionary, account: Dictionary, action_id: String, player_text: String, reply_text: String, day_index: int) -> void:
	var account_id: String = str(account.get("id", ""))
	if account_id.is_empty():
		return
	var messages: Dictionary = state.get("messages", {})
	var thread: Dictionary = _normalize_message_thread(messages.get(account_id, {}))
	thread["account_id"] = account_id
	thread["account_name"] = str(account.get("display_name", ""))
	thread["account_handle"] = str(account.get("handle", ""))
	var rows: Array = thread.get("rows", [])
	rows.append({"sender": "player", "action_id": action_id, "text": player_text, "day_index": day_index})
	rows.append({"sender": "account", "action_id": action_id, "text": reply_text, "day_index": day_index})
	if rows.size() > MAX_MESSAGE_ROWS_PER_THREAD:
		rows = rows.slice(rows.size() - MAX_MESSAGE_ROWS_PER_THREAD, rows.size())
	thread["rows"] = rows
	thread["last_day_index"] = day_index
	thread["unread_count"] = int(thread.get("unread_count", 0)) + 1
	messages[account_id] = thread
	state["messages"] = messages


func _public_conversation_conclusion(conversation_step: int, account_state: Dictionary) -> Dictionary:
	var relationship: int = int(account_state.get("relationship", 0))
	var credibility: int = int(account_state.get("credibility", 0))
	var importance: int = int(account_state.get("importance", 0))
	if conversation_step >= PUBLIC_CHAIN_MAX_STEP:
		var unlocked: bool = relationship >= 18 or credibility >= 7 or importance >= 12
		return {
			"concluded": true,
			"reason": "followup_unlocked" if unlocked else "needs_more_stats",
			"followup_unlocked": unlocked
		}
	if conversation_step >= PUBLIC_CHAIN_SOFT_GATE_STEP and relationship < 8 and credibility < 3 and importance < 6:
		return {
			"concluded": true,
			"reason": "needs_more_stats",
			"followup_unlocked": false
		}
	return {"concluded": false, "reason": "", "followup_unlocked": false}


func _record_timeline_row(state: Dictionary, account_id: String, action_id: String, text: String, post_id: String, day_index: int) -> void:
	var account_states: Dictionary = state.get("account_states", {})
	var account_state: Dictionary = _account_state(account_states, account_id)
	var timeline: Array = account_state.get("timeline", [])
	timeline.append({
		"day_index": day_index,
		"action_id": action_id,
		"text": text,
		"post_id": post_id
	})
	if timeline.size() > MAX_TIMELINE_ROWS_PER_ACCOUNT:
		timeline = timeline.slice(timeline.size() - MAX_TIMELINE_ROWS_PER_ACCOUNT, timeline.size())
	account_state["timeline"] = timeline
	account_states[account_id] = account_state
	state["account_states"] = account_states


func _apply_network_bridge(run_state, state: Dictionary, account: Dictionary, account_state: Dictionary, post: Dictionary, action_id: String, thesis: Dictionary, reply_text: String) -> Dictionary:
	var network_changed: bool = false
	var contact_id: String = _social_contact_id(account)
	if action_id == "connect" and bool(run_state.get_network_contacts().get(contact_id, {}).get("met", false)):
		return {"network_changed": false, "contact_id": contact_id}
	var is_private_social_action: bool = PRIVATE_ACTION_IDS.has(action_id)
	var discover_source_only: bool = action_id == "message_check_in" and _should_discover_social_source(account)
	var promote_to_met: bool = is_private_social_action and action_id != "message_check_in"
	if promote_to_met or discover_source_only:
		_ensure_social_contact_definition(state, account, post)
		var contacts: Dictionary = run_state.get_network_contacts()
		var runtime: Dictionary = contacts.get(contact_id, {}).duplicate(true)
		runtime["relationship"] = max(int(runtime.get("relationship", 0)), int(account_state.get("relationship", 0)))
		if promote_to_met:
			runtime["met"] = true
		runtime["last_tip_note"] = reply_text
		runtime["last_tip_day_index"] = run_state.day_index
		contacts[contact_id] = runtime
		run_state.set_network_contacts(contacts)
		var discoveries: Dictionary = run_state.get_network_discoveries()
		var discovery: Dictionary = discoveries.get(contact_id, {}).duplicate(true)
		var provenance: Dictionary = _twooter_provenance(account, post, action_id)
		discovery["contact_id"] = contact_id
		discovery["discovered"] = true
		discovery["source_type"] = "twooter"
		discovery["source_id"] = str(post.get("id", ""))
		discovery["source_label"] = str(provenance.get("source_label", "Twooter"))
		discovery["source_note"] = str(provenance.get("source_note", "A Twooter exchange became a tracked Network contact."))
		discovery["twooter_origin"] = str(provenance.get("twooter_origin", "public_chatter"))
		discovery["twooter_account_id"] = str(account.get("id", ""))
		discovery["twooter_handle"] = str(account.get("handle", ""))
		discovery["twooter_action_id"] = action_id
		discovery["source_only"] = bool(provenance.get("source_only", false))
		discovery["target_company_id"] = str(post.get("target_company_id", post.get("company_id", "")))
		discovery["target_ticker"] = str(post.get("target_ticker", ""))
		discovery["target_sector_id"] = str(account.get("social_profile", {}).get("sector_id", ""))
		var base_lead_score: int = 58 if discover_source_only else 70
		discovery["lead_score"] = max(int(discovery.get("lead_score", 0)), base_lead_score + int(account_state.get("credibility", 0)) / 3)
		discovery["day_index"] = run_state.day_index
		discoveries[contact_id] = discovery
		run_state.set_network_discoveries(discoveries)
		network_changed = true
	if promote_to_met or discover_source_only:
		_record_network_journal(run_state, account, contact_id, post, action_id, thesis, reply_text)
		network_changed = true
	return {"network_changed": network_changed, "contact_id": contact_id}


func _record_network_journal(run_state, account: Dictionary, contact_id: String, post: Dictionary, action_id: String, thesis: Dictionary, reply_text: String) -> void:
	var journal: Dictionary = run_state.get_network_tip_journal()
	var journal_id: String = "twooter|%s|%s|%d|%d" % [
		contact_id,
		action_id,
		run_state.day_index,
		journal.size()
	]
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = str(thesis.get("ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = str(profile.get("target_ticker", "")).strip_edges().to_upper()
	var provenance: Dictionary = _twooter_provenance(account, post, action_id)
	journal[journal_id] = {
		"id": journal_id,
		"journal_type": "twooter_social",
		"status": "recorded",
		"created_day_index": run_state.day_index,
		"contact_id": contact_id,
		"contact_name": str(account.get("display_name", "Twooter contact")),
		"target_company_id": str(thesis.get("company_id", post.get("target_company_id", ""))),
		"target_ticker": ticker,
		"truth_label": _network_action_label(action_id),
		"confidence_label": "social",
		"tip_read": reply_text,
		"twooter_action_id": action_id,
		"twooter_account_id": str(account.get("id", "")),
		"twooter_handle": str(account.get("handle", "")),
		"twooter_origin": str(provenance.get("twooter_origin", "public_chatter")),
		"source_label": str(provenance.get("source_label", "Twooter")),
		"source_note": str(provenance.get("source_note", "")),
		"source_only": bool(provenance.get("source_only", false)),
		"thesis_id": str(thesis.get("id", "")),
		"thesis_title": str(thesis.get("title", ""))
	}
	run_state.set_network_tip_journal(journal)


func _network_action_label(action_id: String) -> String:
	match action_id:
		"connect":
			return "Connection"
		"ask_source_private":
			return "Source check"
		"share_thesis":
			return "Thesis shared"
		"ask_tip":
			return "Market read"
		"accept_invite":
			return "Event invite"
		"respond_suspicious_request":
			return "Suspicious request"
		_:
			return "Twooter"


func _ensure_social_contact_definition(state: Dictionary, account: Dictionary, post: Dictionary) -> void:
	var definitions: Dictionary = state.get("network_contact_definitions", {})
	var contact_id: String = _social_contact_id(account)
	if definitions.has(contact_id):
		return
	var social_profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var provenance: Dictionary = _twooter_provenance(account, post, "")
	definitions[contact_id] = {
		"id": contact_id,
		"display_name": str(account.get("display_name", "Twooter contact")),
		"role": str(social_profile.get("role", "Twooter account")),
		"intro": str(social_profile.get("intro", "A public market voice you first met through Twooter.")),
		"affiliation_type": "social",
		"affiliation_role": str(social_profile.get("affiliation_role", "public_chatter")),
		"recognition_required": 0,
		"sector_ids": social_profile.get("sector_ids", []).duplicate(true) if typeof(social_profile.get("sector_ids", [])) == TYPE_ARRAY else [],
		"categories": ["twooter", str(post.get("category", "social"))],
		"source_label": str(provenance.get("source_label", "Twooter")),
		"source_note": str(provenance.get("source_note", "")),
		"twooter_origin": str(provenance.get("twooter_origin", "public_chatter")),
		"source_only": bool(provenance.get("source_only", false))
	}
	state["network_contact_definitions"] = definitions


func _reply_text(feed_data: Dictionary, account: Dictionary, post: Dictionary, account_state: Dictionary, action_id: String, thesis: Dictionary, day_index: int, gain_multiplier: float) -> String:
	var context: Dictionary = _dialog_context(account, account_state, post, thesis)
	var pool: Array = _response_pool(feed_data, account, action_id, str(account_state.get("relationship_stage", "stranger")))
	var seed: String = "%s|%s|%s|%d|%d" % [
		str(account.get("id", "")),
		str(post.get("id", "")),
		action_id,
		day_index,
		int(account_state.get("interaction_count", 0))
	]
	var template: String = str(pool[int(abs(hash(seed))) % pool.size()])
	var rendered: String = _render_template(template, context)
	if gain_multiplier <= 0.0:
		rendered += " They have already heard from you today, so this lands more as presence than progress."
	elif gain_multiplier < 1.0:
		rendered += " The extra reply helps a little, but the conversation is cooling for today."
	return rendered


func _private_same_day_reply_text(reply_text: String, gain_multiplier: float, account: Dictionary, post: Dictionary, thesis: Dictionary, day_index: int) -> String:
	if gain_multiplier >= 1.0:
		return reply_text
	var context: Dictionary = _dialog_context(account, {}, post, thesis)
	if gain_multiplier <= 0.0:
		var pause_pool: Array = [
			"Let's pause here for today. Bring one new source, a written thesis, or fresh tape before asking again.",
			"We are circling now. Let this breathe until tomorrow, then come back with something concrete.",
			"That is enough for today. New evidence will make the next message more useful than another ask."
		]
		return _render_dialog_pool(pause_pool, context, "%s|private_pause|%d" % [str(account.get("id", "")), day_index])
	var softened_pool: Array = [
		"%s One more useful pass is fine, but after this I need fresh evidence." % reply_text,
		"%s This helps a little; do not turn the thread into a same-day grind." % reply_text,
		"%s Keep the next message for new tape or a clearer thesis." % reply_text
	]
	return _render_dialog_pool(softened_pool, context, "%s|private_soft|%d|%s" % [str(account.get("id", "")), day_index, reply_text])


func _already_connected_reply_text(account: Dictionary, day_index: int) -> String:
	var pool: Array = [
		"We are already connected. Use the next message for a source, thesis, or fresh read.",
		"Connection is already open. Bring something concrete and we can make the thread useful.",
		"You already have the connection. The relationship grows from better questions now, not another connect ping."
	]
	return _render_dialog_pool(pool, _dialog_context(account, {}, {}, {}), "%s|already_connected|%d" % [str(account.get("id", "")), day_index])


func _response_pool(feed_data: Dictionary, account: Dictionary, action_id: String, stage: String) -> Array:
	var pools: Dictionary = feed_data.get("interaction_response_pools", {}) if typeof(feed_data.get("interaction_response_pools", {})) == TYPE_DICTIONARY else {}
	var account_id: String = str(account.get("id", ""))
	var voice_id: String = str(account.get("voice", ""))
	for key in [
		"%s|%s|%s" % [account_id, action_id, stage],
		"%s|%s" % [account_id, action_id],
		"%s|%s|%s" % [voice_id, action_id, stage],
		"%s|%s" % [voice_id, action_id],
		action_id
	]:
		var pool: Array = pools.get(key, []) if typeof(pools.get(key, [])) == TYPE_ARRAY else []
		var clean_pool: Array = _clean_string_pool(pool)
		if not clean_pool.is_empty():
			return clean_pool
	var fallback_pool: Array = _clean_string_pool(DEFAULT_RESPONSE_POOLS.get(action_id, []))
	if fallback_pool.is_empty():
		fallback_pool = ["{account_name} replies with a short market read."]
	return fallback_pool


func _render_template(template: String, context: Dictionary) -> String:
	var rendered: String = template
	for key_value in context.keys():
		var key: String = str(key_value)
		rendered = rendered.replace("{%s}" % key, str(context.get(key_value, "")))
	return _clean_rendered_template_text(rendered, context)


func _clean_rendered_template_text(text: String, context: Dictionary) -> String:
	var rendered: String = text.strip_edges()
	for fallback_key in ["ticker", "company", "target_ticker", "target_company_name"]:
		var fallback_value: String = str(context.get(fallback_key, "")).strip_edges()
		if fallback_value.is_empty():
			continue
		rendered = rendered.replace("{%s}" % fallback_key, fallback_value)
	for token in ["ticker", "company", "target_ticker", "target_company_name", "account_name", "handle", "thesis_title", "stage", "relationship", "likes_given"]:
		rendered = rendered.replace("{%s}" % token, "")
	for _pass_index in range(4):
		rendered = rendered.replace("For ,", "For this lead,")
		rendered = rendered.replace("for ,", "for this lead,")
		rendered = rendered.replace("For .", "For this lead.")
		rendered = rendered.replace("for .", "for this lead.")
		rendered = rendered.replace("  ", " ")
		rendered = rendered.replace(" ,", ",")
		rendered = rendered.replace(" .", ".")
		rendered = rendered.replace("( ", "(")
		rendered = rendered.replace(" )", ")")
	return rendered.strip_edges()


func _player_public_reply_text(account: Dictionary, post: Dictionary, action_id: String, conversation_step: int, day_index: int) -> String:
	var context: Dictionary = {
		"account_name": str(account.get("display_name", "Account")),
		"ticker": str(post.get("target_ticker", "the setup")),
		"company": str(post.get("target_company_name", post.get("target_ticker", "the name"))),
		"topic": _public_topic_text(post)
	}
	var pools: Dictionary = {
		"reply_support": [
			"I like this read on {ticker}; the setup makes more sense if the next session confirms the flow.",
			"Agree on {ticker}. I am watching whether the story and the trading activity line up.",
			"This is useful context for {ticker}; I would rather track confirmation than chase the first move."
		],
		"reply_skeptic": [
			"I see the angle on {ticker}, but what would make you change your mind if the move fades?",
			"Good thread, but I am not fully convinced on {ticker} until the follow-through is cleaner.",
			"How much of this {ticker} move is real demand versus everyone reacting to the same headline?"
		],
		"ask_source_public": [
			"Can you point to the cleanest public source for the {ticker} angle?",
			"Useful read. Is there a filing, calendar item, or public source I should check for {ticker}?",
			"Before I trust the {ticker} setup, where would you verify the source?"
		]
	}
	var pool: Array = pools.get(action_id, []) if typeof(pools.get(action_id, [])) == TYPE_ARRAY else []
	if pool.is_empty():
		return "I want to reply to this thread with a cleaner market read."
	var seed: String = "%s|%s|%s|%d|%d" % [
		str(account.get("id", "")),
		str(post.get("id", "")),
		action_id,
		conversation_step,
		day_index
	]
	return _render_template(str(pool[int(abs(hash(seed))) % pool.size()]), context)


func _public_topic_text(post: Dictionary) -> String:
	var category: String = str(post.get("category", "")).replace("_", " ").strip_edges()
	if not category.is_empty():
		return category
	var topic: String = str(post.get("public_topic_label", "")).strip_edges()
	if not topic.is_empty():
		return topic
	return "market read"


func _message_dialog_options(feed_data: Dictionary, account: Dictionary, account_state: Dictionary, thread: Dictionary, branch: Dictionary, shareable_theses: Array, daily_action: Dictionary, day_index: int) -> Array:
	if not _dialog_cooldown_reason(branch, day_index).is_empty():
		return []
	var tree_rows: Array = _tree_dialog_options(feed_data, account, account_state, {}, shareable_theses, branch, true, day_index, daily_action)
	if not tree_rows.is_empty():
		return tree_rows
	var candidates: Array = []
	var thesis: Dictionary = {}
	if not shareable_theses.is_empty() and typeof(shareable_theses[0]) == TYPE_DICTIONARY:
		thesis = shareable_theses[0]
	_append_message_option_candidate(candidates, "message_check_in", "")
	if not thesis.is_empty():
		_append_message_option_candidate(candidates, "share_thesis", str(thesis.get("id", "")))
	var social_profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var relationship: int = int(account_state.get("relationship", 0))
	var credibility: int = int(account_state.get("credibility", 0))
	var stage: String = _relationship_stage(relationship, credibility, int(account_state.get("importance", 0)))
	if stage in ["trusted", "inner_circle_candidate"]:
		_append_message_option_candidate(candidates, "accept_invite", "")
	if str(social_profile.get("risk_profile", "")) == "suspicious":
		_append_message_option_candidate(candidates, "respond_suspicious_request", "")
	if relationship < 18:
		_append_message_option_candidate(candidates, "connect", "")
	if credibility < 8:
		_append_message_option_candidate(candidates, "ask_source_private", "")
	_append_message_option_candidate(candidates, "ask_tip", "")
	_append_message_option_candidate(candidates, "connect", "")
	_append_message_option_candidate(candidates, "ask_source_private", "")

	var rows: Array = []
	var thread_rows: Array = thread.get("rows", []) if typeof(thread.get("rows", [])) == TYPE_ARRAY else []
	for candidate_value in candidates:
		if rows.size() >= 3 or typeof(candidate_value) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_value
		var action_id: String = str(candidate.get("id", ""))
		var action_def: Dictionary = ACTION_DEFINITIONS.get(action_id, {})
		if action_def.is_empty():
			continue
		var candidate_thesis: Dictionary = thesis if action_id == "share_thesis" else {}
		var player_text: String = _player_private_message_text(account, action_id, candidate_thesis, thread_rows.size(), day_index)
		player_text = _self_aware_player_text(account, player_text, "%s|%s|fallback|%d|%d" % [str(account.get("id", "")), action_id, thread_rows.size(), day_index])
		rows.append({
			"id": action_id,
			"label": str(action_def.get("label", action_id.capitalize())),
			"player_text": player_text,
			"thesis_id": str(candidate.get("thesis_id", "")),
			"cost_ap": 1,
			"enabled": true
		})
	return rows


func _append_message_option_candidate(candidates: Array, action_id: String, thesis_id: String) -> void:
	if action_id.is_empty():
		return
	for candidate_value in candidates:
		if typeof(candidate_value) == TYPE_DICTIONARY and str(candidate_value.get("id", "")) == action_id:
			return
	candidates.append({"id": action_id, "thesis_id": thesis_id})


func _player_private_message_text(account: Dictionary, action_id: String, thesis: Dictionary, thread_count: int, day_index: int) -> String:
	var context: Dictionary = {
		"account_name": str(account.get("display_name", "Account")),
		"ticker": str(thesis.get("ticker", "the setup")),
		"thesis_title": str(thesis.get("title", "my thesis"))
	}
	var pools: Dictionary = {
		"message_check_in": [
			"I want to compare notes cleanly before I act on anything.",
			"Can we keep this to a clean read and what evidence would confirm it?",
			"I am trying to separate useful context from noise; what are you watching?"
		],
		"connect": [
			"I like how you read the tape; let's keep this connection useful.",
			"Your posts have been useful. I want to stay connected and compare clean reads.",
			"Let's connect, but I want to keep the conversation evidence-first."
		],
		"ask_source_private": [
			"Can you point me to the clean public evidence behind your read?",
			"Before I trust the angle, what source would you verify first?",
			"I want to avoid whispers here. What public source should I check?"
		],
		"share_thesis": [
			"I want to share my thesis, {thesis_title}, and hear what I am missing.",
			"Can you look over {thesis_title} and challenge the weakest part?",
			"I wrote up {thesis_title}; I would value a clean read on the assumptions."
		],
		"ask_tip": [
			"What clean read would you watch next without treating it like a shortcut?",
			"If you had to keep it public and clean, what setup deserves attention?",
			"What would you monitor from here: price, volume, filing, or follow-through?"
		],
		"accept_invite": [
			"I can join, but I want to keep the room focused on clean questions.",
			"I will show up prepared and keep the read evidence-first.",
			"Happy to join if the conversation stays clean and useful."
		],
		"respond_suspicious_request": [
			"I am keeping this clean; if the ask is not public, I am out.",
			"I am not touching anything that depends on a dirty request.",
			"That crosses a line for me. Keep it public or count me out."
		]
	}
	var pool: Array = pools.get(action_id, []) if typeof(pools.get(action_id, [])) == TYPE_ARRAY else []
	if pool.is_empty():
		return _player_message_text(action_id, thesis, {})
	var seed: String = "%s|%s|%s|%d|%d" % [
		str(account.get("id", "")),
		action_id,
		str(thesis.get("id", "")),
		thread_count,
		day_index
	]
	return _render_template(str(pool[int(abs(hash(seed))) % pool.size()]), context)


func _player_message_text(action_id: String, thesis: Dictionary, post: Dictionary) -> String:
	match action_id:
		"reply_support":
			return "Constructive reply on %s." % str(post.get("target_ticker", "the thread"))
		"reply_skeptic":
			return "Skeptical question on %s." % str(post.get("target_ticker", "the thread"))
		"ask_source_public":
			return "Asked for a cleaner source."
		"connect":
			return "Sent a connection request."
		"ask_source_private":
			return "Asked for a cleaner source check."
		"share_thesis":
			return "Shared thesis: %s." % str(thesis.get("title", "Untitled thesis"))
		"ask_tip":
			return "Asked for a clean market read."
		"accept_invite":
			return "Accepted a market-room invitation."
		"respond_suspicious_request":
			return "Kept the suspicious request clean."
		_:
			return "Sent a message."


func _relationship_stage(relationship: int, credibility: int, importance: int) -> String:
	if relationship >= 70 and credibility >= 45 and importance >= 55:
		return "inner_circle_candidate"
	if relationship >= 45:
		return "trusted"
	if relationship >= 18:
		return "familiar"
	return "stranger"


func _importance_score(account_state: Dictionary) -> int:
	var relationship: int = int(account_state.get("relationship", 0))
	var exposure: int = int(account_state.get("exposure", 0))
	var credibility: int = int(account_state.get("credibility", 0))
	return clampi(int(round(float(relationship) * 0.42 + float(exposure) * 0.24 + float(credibility) * 0.34)), 0, 100)


func _thesis_credibility_bonus(thesis: Dictionary) -> int:
	var report: Dictionary = thesis.get("report", {}) if typeof(thesis.get("report", {})) == TYPE_DICTIONARY else {}
	var grade: String = str(report.get("grade", report.get("rating", ""))).to_upper()
	if grade.begins_with("A"):
		return 4
	if grade.begins_with("B"):
		return 2
	if grade.begins_with("C"):
		return 1
	return 0


func _shareable_thesis_rows(player_theses: Dictionary) -> Array:
	var rows: Array = []
	for thesis_value in player_theses.values():
		if typeof(thesis_value) != TYPE_DICTIONARY:
			continue
		var thesis: Dictionary = thesis_value
		if str(thesis.get("status", "open")) != "open":
			continue
		rows.append({
			"id": str(thesis.get("id", "")),
			"title": str(thesis.get("title", "Untitled thesis")),
			"company_id": str(thesis.get("company_id", "")),
			"company_name": str(thesis.get("company_name", "")),
			"ticker": str(thesis.get("ticker", "")),
			"stance": str(thesis.get("stance", "")),
			"horizon": str(thesis.get("horizon", "")),
			"report": thesis.get("report", {}).duplicate(true) if typeof(thesis.get("report", {})) == TYPE_DICTIONARY else {}
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	return rows


func _trending_rows(posts: Array) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for post_value in posts:
		if typeof(post_value) != TYPE_DICTIONARY:
			continue
		var post: Dictionary = post_value
		var tag: String = str(post.get("target_ticker", ""))
		if tag.is_empty():
			tag = str(post.get("sector_name", ""))
		if tag.is_empty() or seen.has(tag):
			continue
		seen[tag] = true
		rows.append({
			"tag": "#%s" % tag,
			"category": str(post.get("public_topic_label", post.get("category", "Market"))),
			"posts": max(int(post.get("likes", 0)) + int(post.get("replies", 0)), 120)
		})
		if rows.size() >= 4:
			break
	return rows


func _who_to_follow_rows(accounts: Array, feed_data: Dictionary) -> Array:
	var rows: Array = []
	for account_value in accounts:
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		if bool(account.get("following", false)):
			continue
		var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
		rows.append({
			"account_id": str(account.get("id", "")),
			"display_name": str(account.get("display_name", "")),
			"handle": str(account.get("handle", "")),
			"verified": bool(account.get("verified", false)),
			"weight": int(profile.get("follow_weight", 50)) + int(account.get("importance", 0))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("weight", 0)) == int(b.get("weight", 0)):
			return str(a.get("display_name", "")) < str(b.get("display_name", ""))
		return int(a.get("weight", 0)) > int(b.get("weight", 0))
	)
	if rows.size() > 3:
		rows = rows.slice(0, 3)
	return rows


func _message_thread_summaries(messages: Dictionary, account_lookup: Dictionary, account_states: Dictionary) -> Array:
	var rows: Array = []
	for account_id_value in messages.keys():
		var account_id: String = str(account_id_value)
		var thread: Dictionary = _normalize_message_thread(messages.get(account_id, {}))
		var account: Dictionary = account_lookup.get(account_id, {})
		var account_state: Dictionary = _account_state(account_states, account_id)
		rows.append({
			"account_id": account_id,
			"account_name": str(thread.get("account_name", account.get("display_name", account_id))),
			"account_handle": str(thread.get("account_handle", account.get("handle", ""))),
			"last_day_index": int(thread.get("last_day_index", 0)),
			"unread_count": int(thread.get("unread_count", 0)),
			"relationship": int(account_state.get("relationship", 0)),
			"relationship_stage": _relationship_stage(int(account_state.get("relationship", 0)), int(account_state.get("credibility", 0)), int(account_state.get("importance", 0))),
			"last_text": _last_thread_text(thread)
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("last_day_index", 0)) > int(b.get("last_day_index", 0))
	)
	return rows


func _last_thread_text(thread: Dictionary) -> String:
	var rows: Array = thread.get("rows", [])
	if rows.is_empty():
		return ""
	var row: Dictionary = rows[rows.size() - 1]
	return str(row.get("text", ""))


func _state_summary(account_states: Dictionary, messages: Dictionary) -> Dictionary:
	var relationship_total: int = 0
	var credibility_total: int = 0
	var inner_candidates: int = 0
	for state_value in account_states.values():
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = state_value
		relationship_total += int(state.get("relationship", 0))
		credibility_total += int(state.get("credibility", 0))
		if str(state.get("relationship_stage", "")) == "inner_circle_candidate":
			inner_candidates += 1
	return {
		"account_count": account_states.size(),
		"message_thread_count": messages.size(),
		"relationship_total": relationship_total,
		"credibility_total": credibility_total,
		"inner_circle_candidates": inner_candidates
	}


func _account_lookup(accounts: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for account_value in accounts:
		if typeof(account_value) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_value
		lookup[str(account.get("id", ""))] = account.duplicate(true)
	return lookup


func _post_by_id(posts: Array, post_id: String) -> Dictionary:
	for post_value in posts:
		if typeof(post_value) == TYPE_DICTIONARY and str(post_value.get("id", "")) == post_id:
			return post_value.duplicate(true)
	return {}


func _account_by_id(accounts: Array, account_id: String) -> Dictionary:
	for account_value in accounts:
		if typeof(account_value) == TYPE_DICTIONARY and str(account_value.get("id", "")) == account_id:
			return account_value.duplicate(true)
	return {}


func _thesis_by_id(theses: Array, thesis_id: String) -> Dictionary:
	for thesis_value in theses:
		if typeof(thesis_value) == TYPE_DICTIONARY and str(thesis_value.get("id", "")) == thesis_id:
			return thesis_value.duplicate(true)
	return {}


func _account_state(account_states: Dictionary, account_id: String) -> Dictionary:
	if account_id.is_empty():
		return _normalize_account_state({})
	return _normalize_account_state(account_states.get(account_id, {}))


func _normalize_account_state(source: Variant) -> Dictionary:
	var row: Dictionary = source if typeof(source) == TYPE_DICTIONARY else {}
	var normalized: Dictionary = {
		"relationship": clampi(int(row.get("relationship", 0)), 0, 100),
		"exposure": clampi(int(row.get("exposure", 0)), 0, 100),
		"credibility": clampi(int(row.get("credibility", 0)), 0, 100),
		"importance": clampi(int(row.get("importance", 0)), 0, 100),
		"following": bool(row.get("following", false)),
		"connected": bool(row.get("connected", false)),
		"likes_given": max(int(row.get("likes_given", 0)), 0),
		"last_like_day_index": int(row.get("last_like_day_index", -1)),
		"like_relationship_progress": float(clamp(float(row.get("like_relationship_progress", 0.0)), 0.0, 0.99)),
		"unfollowed_ask_count": max(int(row.get("unfollowed_ask_count", 0)), 0),
		"last_unfollowed_ask_day_index": int(row.get("last_unfollowed_ask_day_index", -1)),
		"last_interaction_day_index": int(row.get("last_interaction_day_index", -1)),
		"interaction_count": max(int(row.get("interaction_count", 0)), 0),
		"timeline": []
	}
	normalized["importance"] = _importance_score(normalized)
	normalized["relationship_stage"] = _relationship_stage(int(normalized.get("relationship", 0)), int(normalized.get("credibility", 0)), int(normalized.get("importance", 0)))
	for timeline_value in row.get("timeline", []):
		if typeof(timeline_value) != TYPE_DICTIONARY:
			continue
		var timeline_row: Dictionary = timeline_value
		normalized["timeline"].append({
			"day_index": int(timeline_row.get("day_index", 0)),
			"action_id": str(timeline_row.get("action_id", "")),
			"text": str(timeline_row.get("text", "")),
			"post_id": str(timeline_row.get("post_id", ""))
		})
	if normalized["timeline"].size() > MAX_TIMELINE_ROWS_PER_ACCOUNT:
		normalized["timeline"] = normalized["timeline"].slice(normalized["timeline"].size() - MAX_TIMELINE_ROWS_PER_ACCOUNT, normalized["timeline"].size())
	return normalized


func _normalize_post_interaction(source: Variant) -> Dictionary:
	var row: Dictionary = source if typeof(source) == TYPE_DICTIONARY else {}
	var replies: Array = []
	for reply_value in row.get("replies", []):
		if typeof(reply_value) != TYPE_DICTIONARY:
			continue
		var reply: Dictionary = reply_value
		replies.append({
			"account_id": str(reply.get("account_id", "")),
			"action_id": str(reply.get("action_id", "")),
			"player_text": str(reply.get("player_text", "")),
			"reply_text": str(reply.get("reply_text", "")),
			"day_index": int(reply.get("day_index", 0)),
			"relationship_delta": int(reply.get("relationship_delta", 0)),
			"exposure_delta": int(reply.get("exposure_delta", 0)),
			"credibility_delta": int(reply.get("credibility_delta", 0))
		})
	if replies.size() > MAX_PUBLIC_REPLY_ROWS_PER_POST:
		replies = replies.slice(replies.size() - MAX_PUBLIC_REPLY_ROWS_PER_POST, replies.size())
	var conversation_step: int = max(int(row.get("conversation_step", 0)), 0)
	return {
		"replies": replies,
		"interaction_count": max(int(row.get("interaction_count", 0)), 0),
		"last_day_index": int(row.get("last_day_index", -1)),
		"conversation_step": conversation_step,
		"concluded": bool(row.get("concluded", false)),
		"conclusion_reason": str(row.get("conclusion_reason", "")),
		"followup_unlocked": bool(row.get("followup_unlocked", false))
	}


func _normalize_liked_post(source: Variant) -> Dictionary:
	var row: Dictionary = source if typeof(source) == TYPE_DICTIONARY else {}
	return {
		"account_id": str(row.get("account_id", "")),
		"day_index": int(row.get("day_index", -1))
	}


func _normalize_message_thread(source: Variant) -> Dictionary:
	var row: Dictionary = source if typeof(source) == TYPE_DICTIONARY else {}
	var rows: Array = []
	for message_value in row.get("rows", []):
		if typeof(message_value) != TYPE_DICTIONARY:
			continue
		var message: Dictionary = message_value
		rows.append({
			"sender": str(message.get("sender", "")),
			"action_id": str(message.get("action_id", "")),
			"text": str(message.get("text", "")),
			"day_index": int(message.get("day_index", 0))
		})
	if rows.size() > MAX_MESSAGE_ROWS_PER_THREAD:
		rows = rows.slice(rows.size() - MAX_MESSAGE_ROWS_PER_THREAD, rows.size())
	return {
		"account_id": str(row.get("account_id", "")),
		"account_name": str(row.get("account_name", "")),
		"account_handle": str(row.get("account_handle", "")),
		"last_day_index": int(row.get("last_day_index", 0)),
		"unread_count": max(int(row.get("unread_count", 0)), 0),
		"rows": rows
	}


func _normalize_dialog_branch(source: Variant) -> Dictionary:
	var row: Dictionary = source if typeof(source) == TYPE_DICTIONARY else {}
	return {
		"tree_id": str(row.get("tree_id", "")),
		"node_id": str(row.get("node_id", "")),
		"last_option_id": str(row.get("last_option_id", "")),
		"last_action_id": str(row.get("last_action_id", "")),
		"repeat_count": max(int(row.get("repeat_count", 0)), 0),
		"last_day_index": int(row.get("last_day_index", -1)),
		"cooldown_until_day": int(row.get("cooldown_until_day", -1)),
		"cooldown_reason": str(row.get("cooldown_reason", "")),
		"step_count": max(int(row.get("step_count", 0)), 0)
	}


func _clean_string_pool(pool: Array) -> Array:
	var clean: Array = []
	for value in pool:
		var text: String = str(value).strip_edges()
		if not text.is_empty():
			clean.append(text)
	return clean


func _social_contact_id(account: Dictionary) -> String:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var mapped_id: String = str(profile.get("network_contact_id", ""))
	if not mapped_id.is_empty():
		return mapped_id
	return "social_%s" % str(account.get("id", "twooter"))


func _should_discover_social_source(account: Dictionary) -> bool:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	if bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact":
		return true
	return _account_public_post_count(account) <= 0


func _twooter_provenance(account: Dictionary, post: Dictionary, _action_id: String) -> Dictionary:
	var profile: Dictionary = account.get("social_profile", {}) if typeof(account.get("social_profile", {})) == TYPE_DICTIONARY else {}
	var handle: String = str(account.get("handle", "")).strip_edges()
	var ticker: String = str(post.get("target_ticker", "")).strip_edges().to_upper()
	if ticker.is_empty():
		ticker = str(profile.get("target_ticker", "")).strip_edges().to_upper()
	var target_text: String = " for $%s" % ticker if not ticker.is_empty() else ""
	if bool(profile.get("network_source", false)) or str(profile.get("account_origin", "")) == "network_contact":
		return {
			"twooter_origin": "news_handle",
			"source_label": "Twooter handle from News",
			"source_note": "You found %s%s through a News source handle, then followed up in Twooter." % [handle if not handle.is_empty() else "this account", target_text],
			"source_only": true
		}
	if _account_public_post_count(account) <= 0:
		return {
			"twooter_origin": "source_handle",
			"source_label": "Source-only Twooter handle",
			"source_note": "This account has no public posts yet; the lead started from a direct Twooter handle%s." % target_text,
			"source_only": true
		}
	return {
		"twooter_origin": "public_chatter",
		"source_label": "Twooter public chatter",
		"source_note": "A public Twooter exchange became a tracked Network contact%s." % target_text,
		"source_only": false
	}


func _is_social_contact_connected(run_state, account: Dictionary, account_state: Dictionary) -> bool:
	if bool(account_state.get("connected", false)):
		return true
	var contact_id: String = _social_contact_id(account)
	if contact_id.is_empty():
		return false
	return bool(run_state.get_network_contacts().get(contact_id, {}).get("met", false))
