module Api
    module V1
      class VotesController < ApplicationController
        before_action :authenticate_user!
        before_action :set_event

        def create
          vote_type = params[:vote_type].presence || "date"

          if vote_type == "date"
            unless @event.vote_mode
              return render json: { error: "This event uses host selection, not group voting" }, status: :forbidden
            end
            unless @event.tie?
              return render json: { error: "No active tie to vote on" }, status: :unprocessable_entity
            end
          else
            date = params[:chosen_slot].to_s.split("T").first
            unless @event.time_slots_for(date).length > 1
              return render json: { error: "No time options to vote on" }, status: :unprocessable_entity
            end
          end

          vote             = Vote.find_or_initialize_by(user: @current_user, event: @event, vote_type: vote_type)
          vote.chosen_slot = params[:chosen_slot]

          if vote.save
            if vote_type == "time"
              date = params[:chosen_slot].to_s.split("T").first
              render json: {
                chosen_slot: vote.chosen_slot,
                my_vote:     vote.chosen_slot,
                vote_tally:  time_vote_tally(date),
                vote_closed: @event.time_vote_closed?(date)
              }, status: :ok
            else
              render json: {
                chosen_slot: vote.chosen_slot,
                my_vote:     vote.chosen_slot,
                vote_tally:  date_vote_tally,
                vote_closed: @event.tie_vote_closed?
              }, status: :ok
            end
          else
            render json: { error: vote.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        end

        def tally
          unless @event.vote_mode
            return render json: { error: "Vote mode is not enabled for this event" }, status: :forbidden
          end
          my_vote = @event.votes.find_by(user: @current_user, vote_type: "date")&.chosen_slot
          render json: { tally: date_vote_tally, my_vote: my_vote, vote_closed: @event.tie_vote_closed? }
        end

        def time_tally
          date    = params[:date]
          my_vote = @event.votes.find_by(user: @current_user, vote_type: "time")&.chosen_slot
          render json: { tally: time_vote_tally(date), my_vote: my_vote, vote_closed: @event.time_vote_closed?(date) }
        end

        private

        def set_event
          @event = Event.find(params[:event_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Event not found" }, status: :not_found
        end

        def date_vote_tally
          @event.votes
                .where(vote_type: "date")
                .group(:chosen_slot)
                .count
                .map { |slot, count| { slot: slot, count: count } }
                .sort_by { |v| -v[:count] }
        end

        def time_vote_tally(date)
          @event.votes
                .where(vote_type: "time")
                .where("chosen_slot LIKE ?", "#{date}%")
                .group(:chosen_slot)
                .count
                .map { |slot, count| { slot: slot, count: count } }
                .sort_by { |v| -v[:count] }
        end
      end
    end
end
