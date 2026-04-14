# app/controllers/api/v1/auth_controller.rb
module Api
    module V1
      class AuthController < ApplicationController
  
        # POST /api/v1/auth/login
        def login
          user = User.find_by_contact(params[:contact], params[:contact_type])
  
          if user
            user.update(display_name: params[:display_name]) if params[:display_name].present?
            Invite.claim_for_user(user)
            render json: { token: generate_token(user), user: user_json(user) }, status: :ok
          else
            render json: { error: "No account found" }, status: :not_found
          end
        end
  
        # POST /api/v1/auth/register
        # No username required — auto-generated from contact
        def register
          contact      = params[:contact].to_s.strip
          contact_type = params[:contact_type]
  
          # Auto-generate a unique username from the contact
          base = contact_type == "email" ? contact.split("@").first : contact.gsub(/\D/, '')
          base = base.gsub(/[^a-zA-Z0-9_]/, '_').first(20).presence || "user"
          username = base
          suffix   = 1
          while User.exists?(username: username)
            username = "#{base}_#{suffix}"
            suffix  += 1
          end
  
          user_params = {
            username:     username,
            display_name: params[:display_name].presence,
            contact_type: contact_type,
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
  
        # GET /api/v1/auth/me
        def me
          authenticate_user!
          render json: { user: user_json(@current_user) }
        end
  
        private
  
        def user_json(user)
          {
            id:           user.id,
            username:     user.username,
            display_name: user.display_name,
            email:        user.email,
            phone:        user.phone,
            contact_type: user.contact_type,
          }
        end
      end
    end
  end