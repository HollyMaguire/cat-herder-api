require 'rails_helper'

RSpec.describe "Items", type: :request do
  let(:owner) { create(:user) }
  let(:guest) { create(:user) }
  let(:event) { create(:event, owner: owner, items_mode: 'open') }

  def json = JSON.parse(response.body)

  describe "POST /api/v1/events/:event_id/items" do
    it 'creates an item' do
      post "/api/v1/events/#{event.id}/items",
           params: { name: 'Pasta salad' }, headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Pasta salad')
      expect(json['added_by']).to eq(owner.username)
    end

    it 'returns 401 without auth' do
      post "/api/v1/events/#{event.id}/items", params: { name: 'Thing' }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/events/:event_id/items/:id" do
    let!(:item) { create(:item, event: event, added_by: guest) }

    it 'allows the adder to delete' do
      delete "/api/v1/events/#{event.id}/items/#{item.id}", headers: auth_headers_for(guest)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 403 when someone else tries to delete' do
      delete "/api/v1/events/#{event.id}/items/#{item.id}", headers: auth_headers_for(owner)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/events/:event_id/items/:id (claim/unclaim)" do
    let!(:item) { create(:item, event: event) }

    it 'allows a user to claim an item' do
      patch "/api/v1/events/#{event.id}/items/#{item.id}",
            params: { claim: true }, headers: auth_headers_for(guest), as: :json

      expect(response).to have_http_status(:ok)
      expect(json['claimed_by']).to eq(guest.username)
    end

    it 'allows the claimer to unclaim' do
      item.update!(claimed_by: guest)
      patch "/api/v1/events/#{event.id}/items/#{item.id}",
            params: { unclaim: true }, headers: auth_headers_for(guest), as: :json

      expect(response).to have_http_status(:ok)
      expect(json['claimed_by']).to be_nil
    end

    it 'returns 403 when another user tries to unclaim' do
      item.update!(claimed_by: guest)
      outsider = create(:user)
      patch "/api/v1/events/#{event.id}/items/#{item.id}",
            params: { unclaim: true }, headers: auth_headers_for(outsider), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'hides claimed_by from the gift recipient in gift mode' do
      gift_event = create(:event, owner: owner, items_mode: 'gift',
                          gift_hidden_from: guest.username, gift_hidden_from_type: 'username')
      gift_item  = create(:item, event: gift_event, added_by: owner)
      gift_item.update!(claimed_by: owner)

      get "/api/v1/events/#{gift_event.id}/items", headers: auth_headers_for(guest)
      hidden_item = JSON.parse(response.body).find { |i| i['id'] == gift_item.id }
      expect(hidden_item['claimed_by']).to eq('hidden')
    end
  end
end
