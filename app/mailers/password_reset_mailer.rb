class PasswordResetMailer < ApplicationMailer
  def reset_email(user, token)
    @user    = user
    @app_url = ENV.fetch("APP_URL", "http://localhost:5173")
    @reset_url = "#{@app_url}/reset-password?token=#{token}"

    mail(
      to:      user.email,
      subject: "Reset your CatHerder password"
    )
  end
end
