module Api
    module V1
      class UsersController < ApplicationController
        before_action :authenticate_user!

        def me
          render json: {
            id:           @current_user.id,
            username:     @current_user.username,
            email:        @current_user.email,
            phone:        @current_user.phone,
            contact_type: @current_user.contact_type,
            owned_events:   @current_user.owned_events.count,
            invited_events: @current_user.invited_events.count,
          }
        end

        def show
          user = User.find(params[:id])
          render json: {
            id:       user.id,
            username: user.username,
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found
        end

        def update
          if @current_user.update(username: params[:username])
            render json: { username: @current_user.username }
          else
            render json: { error: @current_user.errors.full_messages.join(", ") },
                   status: :unprocessable_entity
          end
        end
      end
    end
  end
