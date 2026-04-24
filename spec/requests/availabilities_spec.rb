require 'rails_helper'

RSpec.describe "Availabilities", type: :request do
  let(:owner) { create(:user) }
  let(:event) { create(:event, owner: owner, date_range_start: Date.today, date_range_end: Date.today + 6) }
  let(:slot)  { Date.today.to_s }

  def json = JSON.parse(response.body)

  describe "POST /api/v1/events/:event_id/availabilities" do
    it 'creates availability and returns results' do
      post "/api/v1/events/#{event.id}/availabilities",
           params: { slots: [ slot ] }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:ok)
      expect(json['slots']).to include(slot)
      expect(json['availability_results']).to be_an(Array)
    end

    it 'upserts — replaces previous submission' do
      create(:availability, event: event, user: owner, slots: [ slot ])
      new_slot = (Date.today + 1).to_s

      post "/api/v1/events/#{event.id}/availabilities",
           params: { slots: [ new_slot ] }, headers: auth_headers_for(owner), as: :json

      expect(json['slots']).to eq([ new_slot ])
      expect(event.availabilities.count).to eq(1)
    end

    it 'returns 422 for slots outside the event window' do
      post "/api/v1/events/#{event.id}/availabilities",
           params: { slots: [ (Date.today + 30).to_s ] }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
