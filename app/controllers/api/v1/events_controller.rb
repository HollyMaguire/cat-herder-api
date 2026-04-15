# app/controllers/api/v1/events_controller.rb
module Api
  module V1
    class EventsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_event,       only: [:show, :update, :destroy, :most_available_date, :resolve_tie]
      before_action :require_owner!,  only: [:update, :destroy, :resolve_tie]

      # GET /api/v1/events — events the current user owns OR is invited to
      def index
        owned   = @current_user.owned_events.includes(:invites, :items)
        invited = @current_user.invited_events.includes(:invites, :items)
        events  = (owned + invited).uniq

        render json: events.map { |e| event_json(e) }
      end

      # GET /api/v1/events/:id
      def show
        render json: event_json(@event)
      end

      # POST /api/v1/events
      # Body: {
      #   eventName, description, voteMode, itemsMode, giftHiddenFrom,
      #   dateRangeStart, dateRangeEnd,
      #   items: ["Pasta salad", "Drinks", ...],
      #   invites: [{ contact: "...", type: "email"|"phone" }, ...]
      # }
      def create
        @event = Event.new(
          owner:             @current_user,
          name:              params[:eventName],
          description:       params[:description],
          vote_mode:           params[:voteMode].presence || false,
          items_mode:        params[:itemsMode]        || "none",
          gift_hidden_from:  params[:giftHiddenFrom],
          date_range_start:  params[:dateRangeStart],
          date_range_end:    params[:dateRangeEnd],
          invite_permission:   params[:invitePermission] || "host",
          vip_permission:      params[:vipPermission]    || "host",
          invite_guest_contact: params[:inviteGuestContact],
          start_time_mode:   params[:startTimeMode]    || "none",
          start_time:        params[:startTime],
        )

        if @event.save
          create_items_for(@event, params[:items])
          create_invites_for(@event, params[:invites])
          render json: event_json(@event), status: :created
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/events/:id
      def update
        if @event.update(
          name:             params[:eventName]      || @event.name,
          description:      params[:description]    || @event.description,
          vote_mode:        params.key?(:voteMode)  ? params[:voteMode] : @event.vote_mode,
          items_mode:       params[:itemsMode]      || @event.items_mode,
          gift_hidden_from: params[:giftHiddenFrom] || @event.gift_hidden_from,
          date_range_start: params[:dateRangeStart] || @event.date_range_start,
          date_range_end:   params[:dateRangeEnd]   || @event.date_range_end,
        )
          render json: event_json(@event)
        else
          render json: { error: @event.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/events/:id
      def destroy
        @event.destroy
        head :no_content
      end

      # GET /api/v1/events/:id/most_available_date
      # Returns availability_results array + tie info
      def most_available_date
        render json: {
          results:  @event.availability_results,
          has_tie:  @event.tie?,
          tied:     @event.tied_slots,
        }
      end

      # POST /api/v1/events/:id/resolve_tie
      # Body: { chosen_slot: "2025-08-14" }
      # Owner picks the winner when vote_mode is false
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
          )

          existing_user = User.find_by_contact(contact, contact_type)
          invite.update(user: existing_user) if existing_user
        end
      end

      def event_json(event)
        {
          id:                event.id,
          name:              event.name,
          description:       event.description,
          vote_mode:         event.vote_mode,
          items_mode:        event.items_mode,
          gift_hidden_from:  event.gift_hidden_from,
          date_range_start:  event.date_range_start,
          date_range_end:    event.date_range_end,
          confirmed_date:    event.confirmed_date,
          status:            event.status,
          invite_permission:    event.invite_permission,
          vip_permission:       event.vip_permission,
          invite_guest_contact: event.invite_guest_contact,
          start_time_mode:   event.start_time_mode,
          start_time:        event.start_time,
          is_owner:          event.owner_id == @current_user&.id,
          owner:             { id: event.owner_id, username: event.owner.username },
          items:             event.items.map { |i| item_json(i) },
          invites:           event.invites.map { |inv| invite_json(inv) },
          availability_results: event.availability_results,
        }
      end

      def item_json(item)
        {
          id:          item.id,
          name:        item.name,
          claimed_by:  item.claimed_by ? item.claimed_by.username : nil,
          added_by:    item.added_by ? item.added_by.username : nil,
          added_by_id: item.added_by_id,
        }
      end

      def invite_json(inv)
        {
          id:           inv.id,
          contact_type: inv.contact_type,
          status:       inv.status,
          is_vip:       inv.is_vip,
          display_label: inv.nickname.presence || inv.user&.display_name,
          username:     inv.user&.username,
        }
      end
    end
  end
end