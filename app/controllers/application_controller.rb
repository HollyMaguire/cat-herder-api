class ApplicationController < ActionController::API
  SECRET = Rails.application.credentials.secret_key_base

  # ── Call before any action that requires auth ──────────────────────────────
  def authenticate_user!
    token   = request.headers["Authorization"]&.split(" ")&.last
    payload = JWT.decode(token, SECRET, true, algorithm: "HS256")[0]
    @current_user = User.find(payload["user_id"])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  # ── Soft auth — sets @current_user if token present, does not block ────────
  def load_current_user
    token = request.headers["Authorization"]&.split(" ")&.last
    return unless token

    payload       = JWT.decode(token, SECRET, true, algorithm: "HS256")[0]
    @current_user = User.find_by(id: payload["user_id"])
  rescue JWT::DecodeError
    nil
  end

  private

  def generate_token(user)
    payload = { user_id: user.id, exp: 30.days.from_now.to_i }
    JWT.encode(payload, SECRET, "HS256")
  end
end
