require 'rails_helper'

RSpec.describe "Invites", type: :request do
  let(:owner)  { create(:user) }
  let(:guest)  { create(:user) }
  let(:event)  { create(:event, owner: owner) }

  def json = JSON.parse(response.body)

  describe "POST /api/v1/events/:event_id/invites" do
    before { ActionMailer::Base.deliveries.clear }

    it 'creates invites and returns them' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: 'a@b.com', type: 'email' }] },
           headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:created)
      expect(json.first['contact_type']).to eq('email')
    end

    it 'ignores blank contacts' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: '', type: 'email' }] },
           headers: auth_headers_for(owner), as: :json

      expect(response).to have_http_status(:created)
      expect(json).to be_empty
    end

    it 'links the invite to an existing user by email' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: guest.email, type: 'email' }] },
           headers: auth_headers_for(owner), as: :json

      invite = event.invites.find_by(contact: guest.email)
      expect(invite.user).to eq(guest)
    end

    it 'sends an invite email when the email address has no account' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: 'newperson@example.com', type: 'email' }] },
           headers: auth_headers_for(owner), as: :json

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to eq(['newperson@example.com'])
    end

    it 'does not send an email when the email address already has an account' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: guest.email, type: 'email' }] },
           headers: auth_headers_for(owner), as: :json

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'does not send an email for phone invites' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: '+15550001234', type: 'phone' }] },
           headers: auth_headers_for(owner), as: :json

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'does not send an email for username invites' do
      post "/api/v1/events/#{event.id}/invites",
           params: { invites: [{ contact: guest.username, type: 'username' }] },
           headers: auth_headers_for(owner), as: :json

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe "PATCH /api/v1/events/:event_id/invites/:id" do
    let!(:invite) { create(:invite, event: event, user: guest) }

    it 'updates RSVP status' do
      patch "/api/v1/events/#{event.id}/invites/#{invite.id}",
            params: { status: 'accepted' }, headers: auth_headers_for(guest), as: :json
      expect(response).to have_http_status(:ok)
      expect(json['status']).to eq('accepted')
    end

    it 'allows owner to set is_vip' do
      patch "/api/v1/events/#{event.id}/invites/#{invite.id}",
            params: { is_vip: true }, headers: auth_headers_for(owner), as: :json
      expect(response).to have_http_status(:ok)
      expect(json['is_vip']).to be true
    end
  end

  describe "DELETE /api/v1/events/:event_id/invites/:id" do
    let!(:invite) { create(:invite, event: event, user: guest) }

    it 'allows owner to remove a guest' do
      delete "/api/v1/events/#{event.id}/invites/#{invite.id}", headers: auth_headers_for(owner)
      expect(response).to have_http_status(:no_content)
    end

    it 'allows the invited guest to remove themselves' do
      delete "/api/v1/events/#{event.id}/invites/#{invite.id}", headers: auth_headers_for(guest)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 403 for an unrelated user' do
      outsider = create(:user)
      delete "/api/v1/events/#{event.id}/invites/#{invite.id}", headers: auth_headers_for(outsider)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
