# app/controllers/api/v1/items_controller.rb
module Api
  module V1
    class ItemsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_event

      # GET /api/v1/events/:event_id/items
      # Hides claimed_by from the gift recipient automatically.
      def index
        render json: @event.items.map { |i| item_json(i) }
      end

      # POST /api/v1/events/:event_id/items
      # Body: { name: "Pasta salad" }
      def create
        item = @event.items.create!(name: params[:name], added_by: @current_user)
        render json: item_json(item), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # PATCH /api/v1/events/:event_id/items/:id
      # Body: { claim: true }  or  { unclaim: true }  or  { name: "new name" }
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

      # DELETE /api/v1/events/:event_id/items/:id  (added_by only)
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

      def require_owner!
        unless @event.owner_id == @current_user.id
          render json: { error: "Only the event owner can do that" }, status: :forbidden
        end
      end

      # Strips claimed_by info from the person the gifts are being hidden from.
      def item_json(item)
        is_hidden_user = @event.items_mode == "gift" &&
                         @event.gift_hidden_from.present? &&
                         (
                           @event.gift_hidden_from.downcase == @current_user.username.downcase ||
                           (@current_user.display_name.present? && @event.gift_hidden_from.downcase == @current_user.display_name.downcase)
                         )

        {
          id:          item.id,
          name:        item.name,
          claimed_by:  is_hidden_user ? (item.claimed_by_id? ? "hidden" : nil) : item.claimed_by&.username,
          added_by:    item.added_by&.username,
          added_by_id: item.added_by_id,
        }
      end
    end
  end
end