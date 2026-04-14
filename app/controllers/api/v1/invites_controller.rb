# app/controllers/api/v1/invites_controller.rb
module Api
  module V1
    class InvitesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_event

      # GET /api/v1/events/:event_id/invites
      def index
        render json: @event.invites.map { |i| invite_json(i) }
      end

      # POST /api/v1/events/:event_id/invites
      # Body: { invites: [{ contact: "...", type: "email"|"phone" }, ...] }
      def create
        created = []
        Array(params[:invites]).each do |inv|
          contact      = inv[:contact] || inv["contact"]
          contact_type = inv[:type]    || inv["type"] || "email"
          next if contact.blank?

          invite = @event.invites.find_or_initialize_by(contact: contact)
          invite.contact_type = contact_type
          invite.nickname     = inv[:nickname] || inv["nickname"] if inv[:nickname] || inv["nickname"]

          if invite.save
            existing_user = User.find_by_contact(contact, contact_type)
            invite.update(user: existing_user) if existing_user
            created << invite_json(invite)
          end
        end
        render json: created, status: :created
      end

      # PATCH /api/v1/events/:event_id/invites/:id
      # Used to mark is_vip, update RSVP status, link a user
      def update
        invite = @event.invites.find(params[:id])
        invite.update!(invite_update_params)
        render json: invite_json(invite)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invite not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # DELETE /api/v1/events/:event_id/invites/:id
      def destroy
        invite = @event.invites.find(params[:id])
        require_owner_or_self!(invite)
        invite.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invite not found" }, status: :not_found
      end

      private

      def set_event
        @event = Event.find(params[:event_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end

      def invite_update_params
        params.permit(:is_vip, :status)
      end

      def require_owner_or_self!(invite)
        is_owner = @event.owner_id == @current_user.id
        is_self  = invite.user_id  == @current_user.id
        unless is_owner || is_self
          render json: { error: "Not authorized" }, status: :forbidden
        end
      end

      def invite_json(inv)
        {
          id:            inv.id,
          contact_type:  inv.contact_type,
          status:        inv.status,
          is_vip:        inv.is_vip,
          display_label: inv.nickname.presence || inv.user&.display_name,
          username:      inv.user&.username,
        }
      end
    end
  end
end