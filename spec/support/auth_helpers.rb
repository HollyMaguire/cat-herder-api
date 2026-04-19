module AuthHelpers
  def auth_headers_for(user)
    secret  = Rails.application.credentials.secret_key_base
    payload = { user_id: user.id, exp: 30.days.from_now.to_i }
    token   = JWT.encode(payload, secret, "HS256")
    { "Authorization" => "Bearer #{token}" }
  end
end
