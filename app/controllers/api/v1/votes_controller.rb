# app/controllers/api/v1/votes_controller.rb
module Api
    module V1
      class VotesController < ApplicationController
        before_action :authenticate_user!
        before_action :set_event
  
        # POST /api/v1/events/:event_id/votes
        # Body: { chosen_slot: "2025-08-14" }
        #
        # Only allowed when event.vote_mode is true.
        # Upserts — re-voting replaces the previous choice.
        def create
          unless @event.vote_mode
            return render json: { error: "This event uses host selection, not group voting" }, status: :forbidden
          end
  
          unless @event.tie?
            return render json: { error: "No active tie to vote on" }, status: :unprocessable_entity
          end
  
          vote             = Vote.find_or_initialize_by(user: @current_user, event: @event)
          vote.chosen_slot = params[:chosen_slot]
  
          if vote.save
            render json: {
              chosen_slot: vote.chosen_slot,
              vote_tally:  vote_tally,
            }, status: :ok
          else
            render json: { error: vote.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end
  
        # GET /api/v1/events/:event_id/votes/tally
        # Returns the current vote counts for each tied slot.
        def tally
          unless @event.vote_mode
            return render json: { error: "Vote mode is not enabled for this event" }, status: :forbidden
          end
          render json: { tally: vote_tally }
        end
  
        private
  
        def set_event
          @event = Event.find(params[:event_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Event not found" }, status: :not_found
        end
  
        def vote_tally
          @event.votes
                .group(:chosen_slot)
                .count
                .map { |slot, count| { slot: slot, count: count } }
                .sort_by { |v| -v[:count] }
        end
      end
    end
  end
  