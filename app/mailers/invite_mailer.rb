class InviteMailer < ApplicationMailer
  def invite_email(invite, event, inviter)
    @event   = event
    @inviter = inviter
    @email   = invite.contact
    @app_url = ENV.fetch("APP_URL", "http://localhost:5173")

    mail(
      to:      invite.contact,
      subject: "You've been invited to #{event.name} on CatHerder"
    )
  end

  def existing_user_invite_email(invite, event, inviter, user)
    @event   = event
    @inviter = inviter
    @user    = user
    @app_url = ENV.fetch("APP_URL", "http://localhost:5173")

    mail(
      to:      user.email,
      subject: "You've been invited to #{event.name} on CatHerder"
    )
  end
end
