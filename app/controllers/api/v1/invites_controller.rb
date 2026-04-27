module Api
  module V1
    class InvitesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_event

      def index
        render json: @event.invites.map { |i| invite_json(i) }
      end

      def create
        created = []
        Array(params[:invites]).each do |inv|
          contact      = inv[:contact] || inv["contact"]
          contact_type = inv[:type]    || inv["type"] || "email"
          next if contact.blank?

          contact = contact.to_s.downcase.strip if contact_type == "username"
          invite = @event.invites.find_or_initialize_by(contact: contact)
          invite.contact_type = contact_type
          invite.nickname     = inv[:nickname] || inv["nickname"] if inv[:nickname] || inv["nickname"]

          if invite.save
            existing_user = User.find_by_contact(contact, contact_type)
            if existing_user
              invite.update(user: existing_user)
            elsif contact_type == "email"
              begin
                InviteMailer.invite_email(invite, @event, @current_user).deliver_now
              rescue => e
                Rails.logger.error "InviteMailer failed for #{contact}: #{e.message}"
              end
            end
            created << invite_json(invite)
          end
        end
        render json: created, status: :created
      end

      def update
        invite = @event.invites.find(params[:id])
        invite.update!(invite_update_params)
        render json: invite_json(invite)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invite not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        invite = @event.invites.find(params[:id])
        require_owner_or_self!(invite)
        return if performed?
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
          display_label: inv.user&.username || inv.nickname.presence || inv.contact,
          username:      inv.user&.username
        }
      end
    end
  end
end
