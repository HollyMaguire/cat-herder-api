module Api
  module V1
    class ItemsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_event

      def index
        render json: @event.items.map { |i| item_json(i) }
      end

      def create
        item = @event.items.create!(name: params[:name], added_by: @current_user)
        render json: item_json(item), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def update
        item = @event.items.find(params[:id])

        if params[:claim]
          item.update!(claimed_by: @current_user)

        elsif params[:unclaim]
          unless item.claimed_by_id == @current_user.id || @event.owner_id == @current_user.id
            return render json: { error: "Not authorized to unclaim this item" }, status: :forbidden
          end
          item.update!(claimed_by: nil)

        elsif params[:name]
          return render json: { error: "Only the event owner can do that" }, status: :forbidden unless @event.owner_id == @current_user.id
          item.update!(name: params[:name])
        end

        render json: item_json(item)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Item not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        item = @event.items.find(params[:id])
        return render json: { error: "Only the person who added this item can delete it" }, status: :forbidden unless item.added_by_id == @current_user.id
        item.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Item not found" }, status: :not_found
      end

      private

      def set_event
        @event = Event.find(params[:event_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end

      def item_json(item)
        hidden_from = @event.gift_hidden_from.to_s.downcase.strip
        hidden_type = @event.gift_hidden_from_type.to_s.presence || "username"
        user_value  = case hidden_type
        when "email" then @current_user.email.to_s.downcase.strip
        when "phone" then @current_user.phone.to_s.strip
        else              @current_user.username.to_s.downcase.strip
        end
        is_hidden_user = @event.items_mode == "gift" &&
                         @event.gift_hidden_from.present? &&
                         hidden_from == user_value

        {
          id:          item.id,
          name:        item.name,
          claimed_by:  is_hidden_user ? (item.claimed_by_id? ? "hidden" : nil) : item.claimed_by&.username,
          added_by:    item.added_by&.username,
          added_by_id: item.added_by_id
        }
      end
    end
  end
end
