extends Node

@export var openai_api_key: String = "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"  # Put your key here
@export var model: String = "grok-3.5-mini"

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)

# Query Grok
func query(prompt: String, callback: Callable) -> void:
	if openai_api_key == "":
		push_warning("No OpenAI API key set!")
		return

	var url: String = "https://api.openai.com/v1/responses"
	var body_dict: Dictionary = {
		"model": model,
		"input": prompt
	}
	var headers: Array = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % openai_api_key
	]

	var json_body: String = JSON.stringify(body_dict)  # Pass as String

	# Connect request_completed for this query
	http_request.connect("request_completed", Callable(self, "_on_request_completed").bind(callback))

	# Send HTTP POST request
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray, callback: Callable) -> void:
	if response_code != 200:
		push_warning("Grok request failed: %s" % response_code)
		callback.call("Error")
		return

	# Parse JSON
	var body_text: String = body.get_string_from_utf8()
	var data = JSON.parse_string(body_text)
	if data.error != OK:
		callback.call("Error parsing response")
		return

	var text: String = ""
	if data.result.has("output") and data.result["output"].size() > 0:
		text = str(data.result["output"][0]["content"][0]["text"])

	callback.call(text)
