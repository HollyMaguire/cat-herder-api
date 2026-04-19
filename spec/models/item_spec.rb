require 'rails_helper'

RSpec.describe Item, type: :model do
  it 'is valid with a name' do
    expect(build(:item)).to be_valid
  end

  it 'requires a name' do
    expect(build(:item, name: '')).not_to be_valid
  end

  it 'rejects names over 120 characters' do
    expect(build(:item, name: 'a' * 121)).not_to be_valid
  end

  describe 'scopes' do
    let(:event) { create(:event) }
    let(:user)  { create(:user) }

    it '.unclaimed returns items without a claimant' do
      unclaimed = create(:item, event: event, claimed_by: nil)
      claimed   = create(:item, event: event, claimed_by: user)

      expect(Item.unclaimed).to include(unclaimed)
      expect(Item.unclaimed).not_to include(claimed)
    end

    it '.claimed returns items with a claimant' do
      unclaimed = create(:item, event: event, claimed_by: nil)
      claimed   = create(:item, event: event, claimed_by: user)

      expect(Item.claimed).to include(claimed)
      expect(Item.claimed).not_to include(unclaimed)
    end
  end
end
