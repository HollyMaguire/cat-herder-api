require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'validations' do
    it 'is valid with required attributes' do
      expect(build(:event)).to be_valid
    end

    it 'requires a name' do
      expect(build(:event, name: '')).not_to be_valid
    end

    it 'rejects end date before start date' do
      event = build(:event, date_range_start: Date.today + 10, date_range_end: Date.today + 5)
      expect(event).not_to be_valid
      expect(event.errors[:date_range_end]).to be_present
    end

    it 'accepts equal start and end date (exact date)' do
      expect(build(:event, date_range_start: Date.today + 7, date_range_end: Date.today + 7)).to be_valid
    end

    it 'rejects invalid items_mode' do
      expect(build(:event, items_mode: 'invalid')).not_to be_valid
    end
  end

  describe '#availability_results' do
    let(:event) { create(:event, date_range_start: Date.today, date_range_end: Date.today + 6) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'returns empty array when no availability submitted' do
      expect(event.availability_results).to eq([])
    end

    it 'tallies submitted slots' do
      slot = Date.today.to_s
      create(:availability, event: event, user: user1, slots: [ slot ])
      create(:availability, event: event, user: user2, slots: [ slot ])

      results = event.availability_results
      match   = results.find { |r| r[:slot] == slot }
      expect(match[:count]).to eq(2)
    end

    it 'excludes slots from declined users' do
      slot = Date.today.to_s
      invite = create(:invite, event: event, user: user1, status: 'declined')
      create(:availability, event: event, user: user1, slots: [ slot ])

      results = event.availability_results
      match   = results.find { |r| r[:slot] == slot }
      expect(match).to be_nil
    end

    context 'with VIP guests' do
      let(:slot_a) { Date.today.to_s }
      let(:slot_b) { (Date.today + 1).to_s }

      it 'only returns VIP-available slots as eligible when a VIP has submitted' do
        invite = create(:invite, event: event, user: user1, is_vip: true)
        create(:invite, event: event, user: user2, is_vip: false)

        create(:availability, event: event, user: user1, slots: [ slot_a ])
        create(:availability, event: event, user: user2, slots: [ slot_a, slot_b ])

        results = event.availability_results
        vip_eligible = results.select { |r| r[:vip_eligible] }

        expect(vip_eligible.map { |r| r[:slot] }).to contain_exactly(slot_a)
        expect(results.find { |r| r[:slot] == slot_b }[:vip_eligible]).to be false
      end

      it 'treats all slots as eligible when no VIP has submitted' do
        create(:invite, event: event, user: user1, is_vip: true)
        create(:availability, event: event, user: user2, slots: [ slot_a, slot_b ])

        results = event.availability_results
        expect(results.all? { |r| r[:vip_eligible] }).to be true
      end
    end
  end

  describe '#tied_slots and #tie?' do
    let(:event) { create(:event, date_range_start: Date.today, date_range_end: Date.today + 6) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'returns no tie when one slot has more votes' do
      create(:availability, event: event, user: user1, slots: [ Date.today.to_s, (Date.today + 1).to_s ])
      create(:availability, event: event, user: user2, slots: [ Date.today.to_s ])

      expect(event.tie?).to be false
      expect(event.tied_slots.length).to eq(1)
    end

    it 'detects a tie when two slots share the top count' do
      slot_a = Date.today.to_s
      slot_b = (Date.today + 1).to_s
      create(:availability, event: event, user: user1, slots: [ slot_a ])
      create(:availability, event: event, user: user2, slots: [ slot_b ])

      expect(event.tie?).to be true
      expect(event.tied_slots.length).to eq(2)
    end
  end

  describe '#results_ready?' do
    let(:event) { create(:event, date_range_start: Date.today, date_range_end: Date.today + 6) }
    let(:user1) { create(:user) }

    it 'returns false when no availability submitted' do
      expect(event.results_ready?).to be false
    end

    it 'returns true when all invited users with accounts have submitted' do
      create(:invite, event: event, user: user1)
      create(:availability, event: event, user: user1, slots: [ Date.today.to_s ])

      expect(event.results_ready?).to be true
    end

    it 'returns false when an invited user has not yet submitted' do
      user2 = create(:user)
      create(:invite, event: event, user: user1)
      create(:invite, event: event, user: user2)
      create(:availability, event: event, user: user1, slots: [ Date.today.to_s ])

      expect(event.results_ready?).to be false
    end

    it 'returns true when the availability deadline has passed' do
      event.update!(availability_deadline: Date.yesterday)
      create(:availability, event: event, user: user1, slots: [ Date.today.to_s ])

      expect(event.results_ready?).to be true
    end

    it 'excludes declined users from the "all submitted" check' do
      user2 = create(:user)
      create(:invite, event: event, user: user1)
      create(:invite, event: event, user: user2, status: 'declined')
      create(:availability, event: event, user: user1, slots: [ Date.today.to_s ])

      expect(event.results_ready?).to be true
    end
  end
end
