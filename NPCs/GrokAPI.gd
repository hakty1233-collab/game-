extends Node

@export var openai_api_key: String = "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"  # Put your key here
@export var model: String = "grok-beta"

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)

# Query Grok
func query(prompt: String, callback: Callable) -> void:
	if openai_api_key == "":
		push_warning("No API key set!")
		callback.call("Hello there!")
		return

	# Correct Grok API endpoint
	var url: String = "https://api.x.ai/v1/chat/completions"
	var body_dict: Dictionary = {
		"messages": [
			{
				"role": "system",
				"content": "You are a friendly NPC in a fantasy RPG game. Keep responses short (1-2 sentences) and in character as a villager or traveler."
			},
			{
				"role": "user", 
				"content": prompt
			}
		],
		"model": model,
		"stream": false,
		"temperature": 0.7
	}
	var headers: Array = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % openai_api_key
	]

	var json_body: String = JSON.stringify(body_dict)

	# Connect request_completed for this query
	if http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.disconnect(_on_request_completed)
	http_request.request_completed.connect(_on_request_completed.bind(callback), CONNECT_ONE_SHOT)

	# Send HTTP POST request
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, callback: Callable) -> void:
	if response_code != 200:
		print("Grok request failed: ", response_code)
		print("Response: ", body.get_string_from_utf8())
		callback.call("Hello, traveler! How are you today?")
		return

	# Parse JSON response
	var body_text: String = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(body_text)
	
	if parse_result != OK:
		print("Error parsing JSON: ", json.error_string)
		callback.call("Greetings, friend!")
		return

	var data = json.data
	var text: String = "Nice day, isn't it?"
	
	# Extract the AI response
	if data.has("choices") and data["choices"].size() > 0:
		var choice = data["choices"][0]
		if choice.has("message") and choice["message"].has("content"):
			text = choice["message"]["content"].strip_edges()

	callback.call(text)
