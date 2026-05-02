module Api
  module V1
    class EventsController < ApplicationController
      before_action :authenticate_user!, except: [ :invite_preview ]
      before_action :set_event,       only: [ :show, :update, :destroy, :most_available_date, :resolve_tie, :confirm_winner, :confirm_time ]
      before_action :require_owner!,  only: [ :update, :destroy, :resolve_tie, :confirm_winner, :confirm_time ]

      def index
        owned   = @current_user.owned_events.includes(:invites, :items)
        invited = @current_user.invited_events.includes(:invites, :items)
        events  = (owned + invited).uniq

        render json: events.map { |e| event_json(e) }
      end

      def show
        render json: event_json(@event)
      end

      def create
        @event = Event.new(
          owner:             @current_user,
          name:              params[:eventName],
          description:       params[:description],
          vote_mode:           params[:voteMode].presence || false,
          items_mode:        params[:itemsMode]        || "none",
          gift_hidden_from:          params[:giftHiddenFrom],
          gift_hidden_from_type:     params[:giftHiddenFromType]     || "username",
          date_range_start:          params[:dateRangeStart],
          date_range_end:            params[:dateRangeEnd],
          date_mode:                 params[:dateMode]               || "range",
          custom_dates:              params[:customDates]            || [],
          invite_permission:         params[:invitePermission]       || "host",
          vip_permission:            params[:vipPermission]          || "host",
          invite_guest_contact:      params[:inviteGuestContact],
          invite_guest_contact_type: params[:inviteGuestContactType] || "username",
          start_time_mode:        params[:startTimeMode]           || "none",
          start_time:             params[:startTime],
          bring_label:            params[:bringLabel],
          availability_deadline:  params[:availabilityDeadline].presence,
        )

        if @event.save
          create_items_for(@event, params[:items])
          create_invites_for(@event, params[:invites])
          render json: event_json(@event), status: :created
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def update
        if @event.update(
          name:                      params[:eventName]              || @event.name,
          description:               params[:description]            || @event.description,
          vote_mode:                 params.key?(:voteMode)          ? params[:voteMode]            : @event.vote_mode,
          items_mode:                params[:itemsMode]              || @event.items_mode,
          gift_hidden_from:          params.key?(:giftHiddenFrom)    ? params[:giftHiddenFrom]       : @event.gift_hidden_from,
          gift_hidden_from_type:     params[:giftHiddenFromType]     || @event.gift_hidden_from_type,
          date_range_start:          params[:dateRangeStart]         || @event.date_range_start,
          date_range_end:            params[:dateRangeEnd]           || @event.date_range_end,
          date_mode:                 params[:dateMode]               || @event.date_mode,
          custom_dates:              params.key?(:customDates)       ? params[:customDates]         : @event.custom_dates,
          invite_permission:         params[:invitePermission]       || @event.invite_permission,
          vip_permission:            params[:vipPermission]          || @event.vip_permission,
          invite_guest_contact:      params.key?(:inviteGuestContact) ? params[:inviteGuestContact]  : @event.invite_guest_contact,
          invite_guest_contact_type: params[:inviteGuestContactType] || @event.invite_guest_contact_type,
          start_time_mode:           params[:startTimeMode]                || @event.start_time_mode,
          start_time:                params.key?(:startTime)               ? params[:startTime]               : @event.start_time,
          bring_label:               params.key?(:bringLabel)              ? params[:bringLabel]              : @event.bring_label,
          availability_deadline:     params.key?(:availabilityDeadline)    ? params[:availabilityDeadline].presence : @event.availability_deadline,
        )
          render json: event_json(@event)
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        @event.destroy
        head :no_content
      end

      def invite_preview
        event = Event.find_by(invite_token: params[:token])
        return render json: { error: "Not found" }, status: :not_found unless event
        render json: { event_name: event.name, host_username: event.owner.username }
      end

      def join_by_token
        event = Event.find_by(invite_token: params[:token])
        return render json: { error: "Invalid invite link" }, status: :not_found unless event

        return render json: { event_id: event.id } if event.invites.exists?(user_id: @current_user.id)

        contact_val = @current_user.contact_type == "email" ? @current_user.email : @current_user.phone
        invite = event.invites.find_by(contact: contact_val, contact_type: @current_user.contact_type)
        invite ||= event.invites.find_by("LOWER(contact) = ? AND contact_type = 'username'", @current_user.username.downcase)

        if invite
          invite.update_columns(user_id: @current_user.id)
        else
          contact = @current_user.email.presence || @current_user.phone
          begin
            event.invites.create!(
              user:         @current_user,
              contact:      contact,
              contact_type: @current_user.contact_type,
            )
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
            event.invites.where(contact: contact).update_all(user_id: @current_user.id)
          end
        end

        render json: { event_id: event.id }
      end

      def most_available_date
        render json: {
          results:  @event.availability_results,
          has_tie:  @event.tie?,
          tied:     @event.tied_slots
        }
      end

      def resolve_tie
        slot = params[:chosen_slot]

        unless @event.tied_slots.map { |s| s[:slot] }.include?(slot)
          return render json: { error: "That slot is not part of a tie" }, status: :unprocessable_entity
        end

        if @event.update(confirmed_date: slot, status: "confirmed")
          render json: { confirmed_date: slot }
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def confirm_winner
        slot = params[:chosen_slot]
        if @event.update(confirmed_date: slot, status: "confirmed")
          render json: { confirmed_date: slot }
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def confirm_time
        time_slot = params[:chosen_slot].to_s
        date      = @event.confirmed_date&.split("T")&.first
        return render json: { error: "No confirmed date yet" }, status: :unprocessable_entity unless date

        new_confirmed = time_slot.include?("T") ? time_slot : "#{date}T#{time_slot}"
        if @event.update(confirmed_date: new_confirmed)
          render json: { confirmed_date: @event.confirmed_date }
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def set_event
        @event = Event.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end

      def require_owner!
        unless @event.owner_id == @current_user.id
          render json: { error: "Only the event owner can do that" }, status: :forbidden
        end
      end

      def create_items_for(event, items_param)
        return unless items_param.is_a?(Array)
        items_param.each do |name|
          next if name.blank?
          event.items.create!(name: name)
        end
      end

      def create_invites_for(event, invites_param)
        return unless invites_param.is_a?(Array)
        invites_param.each do |inv|
          contact      = inv[:contact] || inv["contact"]
          contact_type = inv[:type]    || inv["type"] || "email"
          nickname     = inv[:nickname] || inv["nickname"]
          next if contact.blank?

          invite = event.invites.create!(
            contact:      contact,
            contact_type: contact_type,
            nickname:     nickname,
            is_vip:       inv[:is_vip] || inv["is_vip"] || false,
          )

          existing_user = User.find_by_contact(contact, contact_type)
          if existing_user
            invite.update(user: existing_user)
            if existing_user.email.present?
              begin
                InviteMailer.existing_user_invite_email(invite, event, @current_user, existing_user).deliver_now
              rescue => e
                Rails.logger.error "InviteMailer (existing user) failed for #{existing_user.email}: #{e.message}"
              end
            end
          elsif contact_type == "email"
            begin
              InviteMailer.invite_email(invite, event, @current_user).deliver_now
            rescue => e
              Rails.logger.error "InviteMailer failed for #{contact}: #{e.message}"
            end
          end
        end
      end

      def event_json(event)
        voted_user_ids   = event.availabilities.pluck(:user_id).to_set
        my_invite_record = find_my_invite(event)
        {
          id:                event.id,
          name:              event.name,
          description:       event.description,
          vote_mode:         event.vote_mode,
          items_mode:        event.items_mode,
          gift_hidden_from:  event.gift_hidden_from,
          date_range_start:  event.date_range_start,
          date_range_end:    event.date_range_end,
          date_mode:         event.date_mode,
          custom_dates:      event.custom_dates || [],
          confirmed_date:    event.confirmed_date,
          status:            event.status,
          invite_permission:         event.invite_permission,
          vip_permission:            event.vip_permission,
          invite_guest_contact:      event.invite_guest_contact,
          invite_guest_contact_type: event.invite_guest_contact_type,
          gift_hidden_from_type:     event.gift_hidden_from_type,
          start_time_mode:        event.start_time_mode,
          start_time:             event.start_time,
          bring_label:            event.bring_label,
          availability_deadline:  event.availability_deadline,
          results_ready:          event.results_ready?,
          is_owner:          event.owner_id == @current_user&.id,
          invite_token:      event.owner_id == @current_user&.id ? event.invite_token : nil,
          owner:             { id: event.owner_id, username: event.owner.username },
          items:             event.items.map { |i| item_json(i) },
          invites:           event.invites.map { |inv| invite_json(inv, voted_user_ids) },
          my_slots:          event.availabilities.find_by(user: @current_user)&.slots || [],
          my_invite:         my_invite_record ? invite_json(my_invite_record, voted_user_ids) : nil,
          availability_results: event.availability_results
        }
      end

      def find_my_invite(event)
        return nil unless @current_user

        invite = event.invites.find_by(user_id: @current_user.id)
        return invite if invite

        contact_val = @current_user.contact_type == "email" ? @current_user.email : @current_user.phone
        invite = event.invites.find_by(contact: contact_val, contact_type: @current_user.contact_type)
        invite ||= event.invites.find_by("LOWER(contact) = ? AND contact_type = 'username'", @current_user.username.downcase)

        invite&.update_columns(user_id: @current_user.id) if invite && invite.user_id.nil?
        invite
      end

      def item_json(item)
        {
          id:          item.id,
          name:        item.name,
          claimed_by:  item.claimed_by ? item.claimed_by.username : nil,
          added_by:    item.added_by ? item.added_by.username : nil,
          added_by_id: item.added_by_id
        }
      end

      def invite_json(inv, voted_user_ids = Set.new)
        {
          id:            inv.id,
          contact_type:  inv.contact_type,
          status:        inv.status,
          is_vip:        inv.is_vip,
          display_label: inv.user&.username || inv.nickname.presence || inv.contact,
          username:      inv.user&.username,
          has_voted:     inv.user_id ? voted_user_ids.include?(inv.user_id) : false
        }
      end
    end
  end
end
