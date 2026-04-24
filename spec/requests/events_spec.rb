require 'rails_helper'

RSpec.describe "Events", type: :request do
  let(:owner)  { create(:user) }
  let(:other)  { create(:user) }
  let(:event)  { create(:event, owner: owner) }

  def json = JSON.parse(response.body)

  describe "GET /api/v1/events" do
    it 'returns owned and invited events' do
      owned   = create(:event, owner: owner)
      invited = create(:event)
      create(:invite, event: invited, user: owner)

      get '/api/v1/events', headers: auth_headers_for(owner)
      expect(response).to have_http_status(:ok)
      ids = json.map { |e| e['id'] }
      expect(ids).to include(owned.id, invited.id)
    end

    it 'returns 401 without a token' do
      get '/api/v1/events'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/events/:id" do
    it 'returns the event' do
      get "/api/v1/events/#{event.id}", headers: auth_headers_for(owner)
      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq(event.name)
      expect(json['is_owner']).to be true
    end

    it 'returns is_owner false for a non-owner' do
      get "/api/v1/events/#{event.id}", headers: auth_headers_for(other)
      expect(json['is_owner']).to be false
    end

    it 'returns 404 for missing event' do
      get '/api/v1/events/999999', headers: auth_headers_for(owner)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/events" do
    let(:valid_params) do
      {
        eventName: 'Party', dateRangeStart: Date.today + 7, dateRangeEnd: Date.today + 14,
        itemsMode: 'none', invitePermission: 'host', vipPermission: 'host',
        startTimeMode: 'none', voteMode: false
      }
    end

    it 'creates an event' do
      post '/api/v1/events', params: valid_params, headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Party')
    end

    it 'returns 422 when name is blank' do
      post '/api/v1/events', params: valid_params.merge(eventName: ''), headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/events/:id" do
    it 'updates the event when requester is owner' do
      patch "/api/v1/events/#{event.id}", params: { eventName: 'Updated' }, headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('Updated')
    end

    it 'returns 403 when requester is not owner' do
      patch "/api/v1/events/#{event.id}", params: { eventName: 'Hacked' }, headers: auth_headers_for(other), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/events/:id" do
    it 'destroys the event when requester is owner' do
      delete "/api/v1/events/#{event.id}", headers: auth_headers_for(owner)
      expect(response).to have_http_status(:no_content)
      expect(Event.find_by(id: event.id)).to be_nil
    end

    it 'returns 403 when requester is not owner' do
      delete "/api/v1/events/#{event.id}", headers: auth_headers_for(other)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/events/:id/confirm_winner" do
    let(:slot) { (Date.today + 7).to_s }

    before { create(:availability, event: event, user: owner, slots: [ slot ]) }

    it 'confirms the winner when requester is owner' do
      post "/api/v1/events/#{event.id}/confirm_winner",
           params: { chosen_slot: slot }, headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:ok)
      expect(json['confirmed_date']).to eq(slot)
      expect(event.reload.status).to eq('confirmed')
    end

    it 'returns 403 when requester is not owner' do
      post "/api/v1/events/#{event.id}/confirm_winner",
           params: { chosen_slot: slot }, headers: auth_headers_for(other), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/events/:id/resolve_tie" do
    let(:slot_a) { (Date.today + 7).to_s }
    let(:slot_b) { (Date.today + 8).to_s }
    let(:user2)  { create(:user) }

    before do
      create(:availability, event: event, user: owner, slots: [ slot_a ])
      create(:availability, event: event, user: user2, slots: [ slot_b ])
    end

    it 'resolves a tie when requester is owner' do
      post "/api/v1/events/#{event.id}/resolve_tie",
           params: { chosen_slot: slot_a }, headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:ok)
      expect(json['confirmed_date']).to eq(slot_a)
    end

    it 'returns 422 when slot is not tied' do
      post "/api/v1/events/#{event.id}/resolve_tie",
           params: { chosen_slot: (Date.today + 20).to_s }, headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 when requester is not owner' do
      post "/api/v1/events/#{event.id}/resolve_tie",
           params: { chosen_slot: slot_a }, headers: auth_headers_for(other), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
