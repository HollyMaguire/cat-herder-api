require 'rails_helper'

RSpec.describe InviteMailer, type: :mailer do
  let(:owner)  { create(:user, username: 'holly', email: 'holly@example.com') }
  let(:event)  { create(:event, name: 'Game Night', owner: owner) }
  let(:invite) { create(:invite, event: event, contact: 'guest@example.com', contact_type: 'email') }
  let(:mail)   { InviteMailer.invite_email(invite, event, owner) }

  it 'sends to the invited email address' do
    expect(mail.to).to eq([ 'guest@example.com' ])
  end

  it 'sends from the CatHerder address' do
    expect(mail.from).to eq([ 'CatHerderApp@gmail.com' ])
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

  describe 'existing_user_invite_email' do
    let(:guest)       { create(:user, username: 'alice', email: 'alice@example.com') }
    let(:user_invite) { create(:invite, event: event, contact: 'alice', contact_type: 'username', user: guest) }
    let(:mail)        { InviteMailer.existing_user_invite_email(user_invite, event, owner, guest) }

    it 'sends to the existing user email address' do
      expect(mail.to).to eq([ 'alice@example.com' ])
    end

    it 'sends from the CatHerder address' do
      expect(mail.from).to eq([ 'CatHerderApp@gmail.com' ])
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

    it 'includes a link to the event' do
      expect(mail.body.encoded).to include("/manage/#{event.id}")
    end

    it 'does not include a signup link' do
      expect(mail.body.encoded).not_to include('mode=signup')
    end
  end
end
