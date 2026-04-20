require 'rails_helper'

RSpec.describe Invite, type: :model do
  describe 'validations' do
    it 'is valid with required attributes' do
      expect(build(:invite)).to be_valid
    end

    it 'requires contact' do
      expect(build(:invite, contact: '')).not_to be_valid
    end

    it 'rejects duplicate contact for the same event' do
      event  = create(:event)
      create(:invite, event: event, contact: 'dup@example.com')
      expect(build(:invite, event: event, contact: 'dup@example.com')).not_to be_valid
    end

    it 'allows the same contact on different events' do
      create(:invite, contact: 'shared@example.com')
      expect(build(:invite, contact: 'shared@example.com')).to be_valid
    end

    it 'rejects invalid status' do
      expect(build(:invite, status: 'nope')).not_to be_valid
    end
  end

  describe '.claim_for_user' do
    it 'links un-owned email invites to the matching user' do
      user   = create(:user, email: 'claimer@example.com', contact_type: 'email')
      invite = create(:invite, contact: 'claimer@example.com', contact_type: 'email', user: nil)

      Invite.claim_for_user(user)
      expect(invite.reload.user).to eq(user)
    end

    it 'links un-owned username invites to the matching user' do
      user   = create(:user, username: 'claimme')
      invite = create(:invite, contact: 'claimme', contact_type: 'username', user: nil)

      Invite.claim_for_user(user)
      expect(invite.reload.user).to eq(user)
    end

    it 'does not overwrite an already-owned invite' do
      existing_user = create(:user)
      claiming_user = create(:user, email: 'claimer2@example.com', contact_type: 'email')
      invite = create(:invite, contact: 'claimer2@example.com', contact_type: 'email', user: existing_user)

      Invite.claim_for_user(claiming_user)
      expect(invite.reload.user).to eq(existing_user)
    end
  end
end
