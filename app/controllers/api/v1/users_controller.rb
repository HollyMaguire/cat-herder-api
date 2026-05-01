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
            invited_events: @current_user.invited_events.count
          }
        end

        def show
          user = User.find(params[:id])
          render json: {
            id:       user.id,
            username: user.username
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found
        end

        def pending_invites
          submitted_event_ids = Availability
            .where(user_id: @current_user.id)
            .pluck(:event_id)

          invites = Invite
            .includes(:event)
            .where(user_id: @current_user.id, status: "pending")
            .where.not(event_id: submitted_event_ids)

          render json: invites.map { |i|
            { invite_id: i.id, event_id: i.event_id, event_name: i.event.name }
          }
        end

        def contacts
          # Events the user owns
          owned_event_ids = @current_user.owned_events.pluck(:id)

          # Events where the user has a linked invite
          linked_event_ids = Invite.where(user_id: @current_user.id).pluck(:event_id)

          # Events where the user has an unlinked invite matching their contact info
          contact_event_ids = unlinked_invite_event_ids

          all_event_ids = (owned_event_ids + linked_event_ids + contact_event_ids).uniq
          return render json: [] if all_event_ids.empty?

          invites = Invite.includes(:user).where(event_id: all_event_ids)

          my_contacts = [ @current_user.email, @current_user.phone, @current_user.username ]
            .compact.map { |c| c.downcase }

          seen = {}
          invites.each do |invite|
            next if my_contacts.include?(invite.contact.to_s.downcase)
            uname = invite.user&.username
            key = uname.present? ? "username:#{uname.downcase}" : "#{invite.contact_type}:#{invite.contact.to_s.downcase}"
            existing = seen[key]
            if !existing || (invite.nickname.present? && existing[:nickname].blank?)
              seen[key] = {
                contact:      uname.present? ? uname : invite.contact,
                contact_type: uname.present? ? "username" : invite.contact_type,
                nickname:     invite.nickname,
                username:     uname,
              }
            end
          end

          # Also include owners of events the user attended as a guest
          guest_event_ids = (linked_event_ids + contact_event_ids).uniq - owned_event_ids
          if guest_event_ids.any?
            Event.where(id: guest_event_ids).includes(:owner).each do |event|
              owner = event.owner
              next if my_contacts.include?(owner.username.downcase)
              key = "username:#{owner.username.downcase}"
              seen[key] ||= {
                contact:      owner.username,
                contact_type: "username",
                nickname:     nil,
                username:     owner.username,
              }
            end
          end

          render json: seen.values
        end

        def update
          if @current_user.update(username: params[:username])
            render json: { username: @current_user.username }
          else
            render json: { error: @current_user.errors.full_messages.join(", ") },
                   status: :unprocessable_entity
          end
        end

        private

        def unlinked_invite_event_ids
          conditions = []
          values = []
          if @current_user.email.present?
            conditions << "(contact = ? AND contact_type = 'email')"
            values << @current_user.email
          end
          if @current_user.phone.present?
            conditions << "(contact = ? AND contact_type = 'phone')"
            values << @current_user.phone
          end
          conditions << "(LOWER(contact) = ? AND contact_type = 'username')"
          values << @current_user.username.downcase
          Invite.where(user_id: nil)
                .where(conditions.join(" OR "), *values)
                .pluck(:event_id)
        end
      end
    end
end
