require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with email and username' do
      expect(build(:user)).to be_valid
    end

    it 'is valid with phone instead of email' do
      expect(build(:phone_user)).to be_valid
    end

    it 'requires a username' do
      expect(build(:user, username: '')).not_to be_valid
    end

    it 'requires username uniqueness (case-insensitive)' do
      create(:user, username: 'Holly')
      expect(build(:user, username: 'holly')).not_to be_valid
    end

    it 'requires password of at least 6 characters' do
      expect(build(:user, password: 'abc')).not_to be_valid
    end

    it 'requires email or phone to be present' do
      user = build(:user, email: '', phone: '')
      expect(user).not_to be_valid
      expect(user.errors[:base]).to include("Email or phone number is required")
    end

    it 'rejects malformed email' do
      expect(build(:user, email: 'not-an-email')).not_to be_valid
    end

    it 'normalizes email to lowercase on save' do
      user = create(:user, email: 'HOLLY@EXAMPLE.COM')
      expect(user.email).to eq('holly@example.com')
    end
  end

  describe '.find_by_contact' do
    let!(:user) { create(:user, email: 'test@example.com', username: 'testuser') }

    it 'finds by email' do
      expect(User.find_by_contact('test@example.com', 'email')).to eq(user)
    end

    it 'finds by email case-insensitively' do
      expect(User.find_by_contact('TEST@EXAMPLE.COM', 'email')).to eq(user)
    end

    it 'finds by username case-insensitively' do
      expect(User.find_by_contact('TESTUSER', 'username')).to eq(user)
    end

    it 'returns nil when not found' do
      expect(User.find_by_contact('nobody@example.com', 'email')).to be_nil
    end
  end
end
