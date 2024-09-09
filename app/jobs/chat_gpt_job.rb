require 'net/http'

class ChatGptJob < ApplicationJob
  queue_as :default

  def perform(channel, user, prompt)
    url = UserChat.where(user_id: user).last.url

    system_prompt = "Extract documentation and files from #{url}. Write the technical documentation of it, and answer from the documentation.
Answer questions as from user perspective, dumb it down without code examples, just the facts. You behave as official documentation, and fully check for the facts.
Act as the app is installed and running, and answer it like you would answer to the project manager and not to the developer.
Do not show or include the code in the answers.
Do not offer reading official README file as you should behave like you are official documentation!
Only answer within the scope of those 2 urls, do not add any answers that are from other parts outside of that scope. Do not answer with server infrastructure specific. Do not add to the answer anything that would require any code changes
. Do not hallucinate. Double check before answering."
    uri = URI.parse("https://api.openai.com/v1/chat/completions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = {
      temperature: 1,
      model: "gpt-4o-2024-08-06",
      messages: [
        { "role": "system", "content": system_prompt },
        { "role": "user", "content": prompt }
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "documentation",
          schema: {
            type: "object",
            properties: {
              response: {
                type: "string"
              }
            }
          }
        }
      }
    }.to_json

    request['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"

    response = http.request(request)
    # parse whole response to JSON
    response_body = JSON.parse(response.body).deep_symbolize_keys

    response = JSON.parse(response_body.dig(:choices, 0, :message, :content)).dig("response")

    # Send the response back to Slack
    client = Slack::Web::Client.new
    client.chat_postMessage(channel: channel, text: response)
  end
end