require 'rails_helper'

RSpec.describe InviteMailer, type: :mailer do
  let(:owner)  { create(:user, username: 'holly', email: 'holly@example.com') }
  let(:event)  { create(:event, name: 'Game Night', owner: owner) }
  let(:invite) { create(:invite, event: event, contact: 'guest@example.com', contact_type: 'email') }
  let(:mail)   { InviteMailer.invite_email(invite, event, owner) }

  it 'sends to the invited email address' do
    expect(mail.to).to eq(['guest@example.com'])
  end

  it 'sends from the CatHerder address' do
    expect(mail.from).to eq(['CatHerderApp@gmail.com'])
  end

  it 'includes the event name in the subject' do
    expect(mail.subject).to include('Game Night')
  end

  it 'includes the event name in the body' do
    expect(mail.body.encoded).to include('Game Night')
  end

  it 'includes the inviter username in the body' do
    expect(mail.body.encoded).to include('holly')
  end

  it 'includes a signup link with the email prefilled' do
    expect(mail.body.encoded).to include('mode=signup')
    expect(mail.body.encoded).to include('guest%40example.com')
  end
end
