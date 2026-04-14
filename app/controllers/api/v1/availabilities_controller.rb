# app/controllers/api/v1/availabilities_controller.rb
module Api
    module V1
      class AvailabilitiesController < ApplicationController
        before_action :authenticate_user!
        before_action :set_event
  
        # POST /api/v1/events/:event_id/availabilities
        # Body: { slots: ["2025-08-10", "2025-08-14", ...] }
        #
        # Upserts — re-submitting replaces the previous selection.
        # Validates every slot falls within the event's date range.
        def create
          avail        = Availability.find_or_initialize_by(user: @current_user, event: @event)
          avail.slots  = Array(params[:slots]).uniq.sort
  
          if avail.save
            render json: {
              id:      avail.id,
              user_id: avail.user_id,
              slots:   avail.slots,
              # Return updated aggregate results so the frontend can refresh immediately
              availability_results: @event.reload.availability_results,
            }, status: :ok
          else
            render json: { error: avail.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end
  
        private
  
        def set_event
          @event = Event.find(params[:event_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Event not found" }, status: :not_found
        end
      end
    end
  end
  