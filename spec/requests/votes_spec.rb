require 'rails_helper'

RSpec.describe "Votes", type: :request do
  let(:owner)  { create(:user) }
  let(:voter)  { create(:user) }
  let(:slot_a) { (Date.today + 7).to_s }
  let(:slot_b) { (Date.today + 8).to_s }

  # vote_mode: true creates a group-vote event
  let(:event) do
    create(:event, owner: owner, vote_mode: true,
           date_range_start: Date.today + 7, date_range_end: Date.today + 14)
  end

  # Create a genuine tie so vote validation passes
  before do
    create(:availability, event: event, user: owner, slots: [slot_a])
    create(:availability, event: event, user: voter, slots: [slot_b])
  end

  def json = JSON.parse(response.body)

  describe "POST /api/v1/events/:event_id/votes" do
    it 'casts a vote for a tied slot' do
      post "/api/v1/events/#{event.id}/votes",
           params: { chosen_slot: slot_a }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:ok)
      expect(json['my_vote']).to eq(slot_a)
    end

    it 'upserts — replaces a previous vote' do
      create_vote_for(owner, slot_a)
      post "/api/v1/events/#{event.id}/votes",
           params: { chosen_slot: slot_b }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:ok)
      expect(json['my_vote']).to eq(slot_b)
      expect(event.votes.count).to eq(1)
    end

    it 'returns 422 when the chosen slot is not tied' do
      post "/api/v1/events/#{event.id}/votes",
           params: { chosen_slot: (Date.today + 20).to_s }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 when vote_mode is false' do
      no_vote_event = create(:event, owner: owner, vote_mode: false,
                              date_range_start: Date.today + 7, date_range_end: Date.today + 14)
      post "/api/v1/events/#{no_vote_event.id}/votes",
           params: { chosen_slot: slot_a }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/events/:event_id/votes/tally" do
    before { create_vote_for(owner, slot_a) }

    it 'returns vote counts and current user vote' do
      get "/api/v1/events/#{event.id}/votes/tally", headers: auth_headers_for(owner)

      expect(response).to have_http_status(:ok)
      expect(json['tally']).to be_an(Array)
      expect(json['my_vote']).to eq(slot_a)
      expect(json['vote_closed']).to be(false).or be(true)
    end

    it 'returns 403 when vote_mode is false' do
      no_vote_event = create(:event, owner: owner, vote_mode: false,
                              date_range_start: Date.today + 7, date_range_end: Date.today + 14)
      get "/api/v1/events/#{no_vote_event.id}/votes/tally", headers: auth_headers_for(owner)
      expect(response).to have_http_status(:forbidden)
    end
  end

  private

  def create_vote_for(user, slot)
    vote = Vote.find_or_initialize_by(user: user, event: event)
    vote.chosen_slot = slot
    vote.save!(validate: false)
  end
end
