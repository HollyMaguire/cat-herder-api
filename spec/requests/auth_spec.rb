require 'rails_helper'

RSpec.describe "Auth", type: :request do
  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: 'holly@example.com', password: 'secret123') }

    it 'returns token and user on valid credentials' do
      post '/api/v1/auth/login', params: { contact: 'holly@example.com', contact_type: 'email', password: 'secret123' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json['token']).to be_present
      expect(json['user']['email']).to eq('holly@example.com')
    end

    it 'returns 401 on wrong password' do
      post '/api/v1/auth/login', params: { contact: 'holly@example.com', contact_type: 'email', password: 'wrong' }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 when user not found' do
      post '/api/v1/auth/login', params: { contact: 'nobody@example.com', contact_type: 'email', password: 'x' }, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/auth/register" do
    it 'creates a user and returns a token' do
      post '/api/v1/auth/register', params: {
        contact: 'new@example.com', contact_type: 'email',
        username: 'newuser', password: 'password123'
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(json['token']).to be_present
      expect(json['user']['username']).to eq('newuser')
    end

    it 'returns 422 on duplicate email' do
      create(:user, email: 'taken@example.com')
      post '/api/v1/auth/register', params: {
        contact: 'taken@example.com', contact_type: 'email',
        username: 'someone', password: 'password123'
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 on missing username' do
      post '/api/v1/auth/register', params: {
        contact: 'ok@example.com', contact_type: 'email',
        username: '', password: 'password123'
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user) }

    it 'returns the current user when authenticated' do
      get '/api/v1/auth/me', headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)
      expect(json['user']['username']).to eq(user.username)
    end

    it 'returns 401 without a token' do
      get '/api/v1/auth/me'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  private

  def json
    JSON.parse(response.body)
  end
end
