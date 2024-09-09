class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  skip_before_action :verify_authenticity_token

  def doc

  end

  def settings
    url = params[:text]

    UserChat.create(
      user_id: params[:user_id],
      url: url
    )

    render :json => {
      text: "URL has been saved: #{url}"
    }
  end

  def slack
    head :ok

    event_data = params[:event]

    return if event_data[:bot_id].present? and return

    case event_data[:type]
    when 'message'
      handle_message(event_data)
    else
      return
    end
  end

  private

  def handle_message(event_data)
    channel = event_data[:channel]
    user = event_data[:user]
    text = event_data[:text]

    ChatGptJob.perform_later(channel, user, text)
  end
end
