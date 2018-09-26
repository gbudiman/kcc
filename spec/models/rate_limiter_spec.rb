require 'rails_helper'

RSpec.describe RateLimiter, type: :model do
  before :each do
    @client = OpenSSL::PKey::EC.generate('secp256k1')
  end

  it 'should derive shared secret correctly' do
    public_key = RateLimiter.handshake @client.public_key
    shared_secret = @client.dh_compute_key(public_key)
    stored_key = KeyMaster.find_by(token: Base64.encode64(shared_secret))
    
    expect(Base64.decode64(stored_key.token)).to eq shared_secret
  end

  context 'with properly setup token' do
    before :each do
      handshake = RateLimiter.handshake(@client.public_key, threshold: 3)
      @shared_secret = Base64.encode64(@client.dh_compute_key(handshake))
    end

    it 'should record 3 accesses properly, then throw exception' do
      3.times do 
        access = RateLimiter.access(@shared_secret)
        expect(RateLimiter.find(access.id)).not_to be nil
      end

      expect do
        RateLimiter.access(@shared_secret)
      end.to raise_error(RateLimiter::Limited, /rate limited/)
    end
  end

  context 'with invalid token' do
    it 'should raise InvalidToken exception' do
      expect do
        RateLimiter.access('non-existant token')
      end.to raise_error(RateLimiter::InvalidToken, /No such token/)
    end
  end

  context 'short period' do
    before :each do
      handshake = RateLimiter.handshake(@client.public_key, threshold: 10, period: 5.seconds)
      @shared_secret = Base64.encode64(@client.dh_compute_key(handshake))
    end

    it 'should successfully access 10 times, followed by exceptions' do
      10.times do
        expect(RateLimiter.access(@shared_secret).id).not_to be nil
      end

      5.times do
        expect do 
          RateLimiter.access(@shared_secret)
        end.to raise_error(RateLimiter::Limited, /rate limited/)
      end

      puts 'Sleeping for 5 seconds to replenish access quota...'
      sleep 5

      10.times do
        expect(RateLimiter.access(@shared_secret).id).not_to be nil
      end
    end
  end
end
