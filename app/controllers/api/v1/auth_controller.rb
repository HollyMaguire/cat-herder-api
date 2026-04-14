# app/controllers/api/v1/auth_controller.rb
module Api
    module V1
      class AuthController < ApplicationController
  
        # POST /api/v1/auth/login
        # Body: { contact: "user@email.com", contact_type: "email" }
        #
        # Returns 200 + JWT if user found.
        # Returns 404 if no user — frontend then shows username setup screen.
        def login
          user = User.find_by_contact(params[:contact], params[:contact_type])
  
          if user
            # Claim any pending invites that match this contact
            Invite.claim_for_user(user)
            render json: { token: generate_token(user), user: user_json(user) }, status: :ok
          else
            render json: { error: "No account found" }, status: :not_found
          end
        end
  
        # POST /api/v1/auth/register
        # Body: { contact: "...", contact_type: "email"|"phone", username: "..." }
        #
        # Creates a new user and returns a JWT.
        def register
          user_params = {
            username:     params[:username],
            contact_type: params[:contact_type],
          }
  
          if params[:contact_type] == "email"
            user_params[:email] = params[:contact]
          else
            user_params[:phone] = params[:contact]
          end
  
          user = User.new(user_params)
  
          if user.save
            Invite.claim_for_user(user)
            render json: { token: generate_token(user), user: user_json(user) }, status: :created
          else
            render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end
  
        # GET /api/v1/auth/me  — returns the current user from token
        def me
          authenticate_user!
          render json: { user: user_json(@current_user) }
        end
  
        private
  
        def user_json(user)
          {
            id:           user.id,
            username:     user.username,
            email:        user.email,
            phone:        user.phone,
            contact_type: user.contact_type,
          }
        end
      end
    end
  end
  