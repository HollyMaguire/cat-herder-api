require 'rails_helper'

RSpec.describe Availability, type: :model do
  let(:event) { create(:event, date_range_start: Date.today, date_range_end: Date.today + 6) }
  let(:user)  { create(:user) }

  it 'is valid with slots inside the event window' do
    avail = build(:availability, event: event, user: user, slots: [Date.today.to_s])
    expect(avail).to be_valid
  end

  it 'rejects slots outside the event date range' do
    avail = build(:availability, event: event, user: user, slots: [(Date.today + 30).to_s])
    expect(avail).not_to be_valid
    expect(avail.errors[:slots]).to be_present
  end

  it 'rejects non-date slot values' do
    avail = build(:availability, event: event, user: user, slots: ['not-a-date'])
    expect(avail).not_to be_valid
  end

  it 'accepts datetime slots (YYYY-MM-DDTHH:00) within range' do
    slot  = "#{Date.today}T09:00"
    avail = build(:availability, event: event, user: user, slots: [slot])
    expect(avail).to be_valid
  end
end
