module Api
  module V1
    class AuthController < ApplicationController
      def login
        user = User.find_by_contact(params[:contact], params[:contact_type])

        if user.nil?
          return render json: { error: "No account found" }, status: :not_found
        end

        unless user.authenticate(params[:password].to_s)
          return render json: { error: "Incorrect password" }, status: :unauthorized
        end

        Invite.claim_for_user(user)
        render json: { token: generate_token(user), user: user_json(user) }, status: :ok
      end

      def register
        contact      = params[:contact].to_s.strip
        contact_type = params[:contact_type]
        username     = params[:username].to_s.strip

        user_params = {
          username:     username,
          display_name: params[:display_name].presence,
          contact_type: contact_type,
          password:     params[:password]
        }

        if contact_type == "email"
          user_params[:email] = contact
        else
          user_params[:phone] = contact
        end

        user = User.new(user_params)

        if user.save
          Invite.claim_for_user(user)
          render json: { token: generate_token(user), user: user_json(user) }, status: :created
        else
          render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def me
        authenticate_user!
        return if performed?
        render json: { user: user_json(@current_user) }
      end

      def forgot_password
        signup_type = params[:signup_type].to_s
        email       = params[:email].to_s.downcase.strip
        phone       = params[:phone].to_s.strip

        user = if signup_type == "phone"
          User.find_by(phone: phone)
        else
          User.find_by(email: email)
        end

        if user.nil?
          return render json: { error: "No account found" }, status: :not_found
        end

        if signup_type == "phone"
          if email.blank?
            return render json: { error: "Email address is required to send the reset link" }, status: :unprocessable_entity
          end
          user.email = email
          unless user.valid?
            return render json: { error: user.errors[:email].first || "Invalid email address" }, status: :unprocessable_entity
          end
        end

        token = SecureRandom.hex(32)
        user.assign_attributes(password_reset_token: token, password_reset_sent_at: Time.current)
        user.save!

        begin
          PasswordResetMailer.reset_email(user, token).deliver_now
        rescue => e
          Rails.logger.error "PasswordResetMailer failed for #{user.email}: #{e.message}"
        end

        render json: { message: "Password reset email sent" }, status: :ok
      end

      def reset_password
        token    = params[:token].to_s
        password = params[:password].to_s

        user = User.find_by(password_reset_token: token)

        if user.nil?
          return render json: { error: "Invalid or expired reset link" }, status: :unprocessable_entity
        end

        if user.password_reset_sent_at < 1.hour.ago
          return render json: { error: "Reset link has expired" }, status: :unprocessable_entity
        end

        if password.length < 6
          return render json: { error: "Password must be at least 6 characters" }, status: :unprocessable_entity
        end

        user.update!(password: password, password_reset_token: nil, password_reset_sent_at: nil)
        render json: { message: "Password updated" }, status: :ok
      end

      private

      def user_json(user)
        {
          id:           user.id,
          username:     user.username,
          display_name: user.display_name,
          email:        user.email,
          phone:        user.phone,
          contact_type: user.contact_type
        }
      end
    end
  end
end
