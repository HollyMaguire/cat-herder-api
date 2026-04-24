module Api
    module V1
      class VotesController < ApplicationController
        before_action :authenticate_user!
        before_action :set_event

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
              my_vote:     vote.chosen_slot,
              vote_tally:  vote_tally,
              vote_closed: @event.tie_vote_closed?
            }, status: :ok
          else
            render json: { error: vote.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end

        def tally
          unless @event.vote_mode
            return render json: { error: "Vote mode is not enabled for this event" }, status: :forbidden
          end
          my_vote = @event.votes.find_by(user: @current_user)&.chosen_slot
          render json: { tally: vote_tally, my_vote: my_vote, vote_closed: @event.tie_vote_closed? }
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
