require 'rails_helper'

RSpec.describe RateLimiter, type: :model do
  before :each do
    @client = OpenSSL::PKey::EC.generate('secp256k1')
    @rand = Random.new()
  end

  it 'should execute basic task correctly' do
    r = RateLimiter.new throws: true

    4.times do |i|
      r.limit :expensive, nonce: i do
        sleep 1
      end
    end

    4.times do |i|
      expect(r.get_status :expensive, i).to eq 'pending'
    end

    expect do 
      r.limit :should_raise_exception
    end.to raise_exception(RateLimiter::Limited)
  end

  it 'should not throw exception when not configured to do so' do
    r = RateLimiter.new throws: false

    40.times do 
      r.limit :expensive do
        sleep 1
      end
    end
  end

  it 'should derive shared secret correctly' do
    public_key = Gatekeeper.handshake @client.public_key
    shared_secret = @client.dh_compute_key(public_key)
    stored_key = KeyMaster.find_by(token: Base64.encode64(shared_secret))
    
    expect(Base64.decode64(stored_key.token)).to eq shared_secret
  end

  context 'with properly setup token' do
    before :each do
      handshake = Gatekeeper.handshake(@client.public_key, threshold: 3)
      @shared_secret = Base64.encode64(@client.dh_compute_key(handshake))
    end

    it 'should record at least 3 accesses properly, and set the state appropriately upon completion' do
      exec_results = []
      promises = []
      3.times do |i|
        promises.push(Gatekeeper.access(@shared_secret, symfunc: :my_func, nonce: i))
      end

      expect(Gatekeeper.get_current_usage_cost(@shared_secret)).to be_within(0.1).of 3

      3.times do |i|
        expect(Gatekeeper.get_state(@shared_secret, :my_func, i).status).to eq 'pending'
      end

      Concurrent::Promise.zip(*promises).execute.then do |results|
        exec_results = results.map{ |r| r.status }
      end.wait

      expect(exec_results.uniq).to contain_exactly('completed')
    end

    it 'once invalidated should raise ExpiredToken' do
      Gatekeeper.invalidate(@shared_secret)

      expect do
        Gatekeeper.access(@shared_secret)
      end.to raise_error(RateLimiter::ExpiredToken)
    end
  end

  context 'with invalid token' do
    it 'should raise InvalidToken exception' do
      expect do
        Gatekeeper.access('non-existant token')
      end.to raise_error(RateLimiter::InvalidToken, /No such token/)
    end
  end

  context 'short-period bursts' do
    before :each do
      handshake = Gatekeeper.handshake(@client.public_key, threshold: 10, period: 5.seconds)
      @shared_secret = Base64.encode64(@client.dh_compute_key(handshake))
    end

    it 'should successfully access at least 10 times, then the rest should be rejected' do
      promises = {}
      rejections = {}
      results = nil
      iterations = 50

      iterations.times do |i|
        begin
          promises[i] = Gatekeeper.access(@shared_secret)
        rescue RateLimiter::Limited => e
          cost = e.message.match(/cost\: ([\d\.]+)/)
          rejections[i] = cost[1].to_f
        end
      end

      Concurrent::Promise.zip(*promises.values).execute.then do |_results|
        results = _results
      end.wait


      puts 'The following iterations were rejected due to rate-limiting:'
      rejections.each do |k, v|
        puts sprintf('%3d: %.2f', k, v)
      end

      expect(results.length).to be > 10
      expect(rejections.keys.length).to eq (iterations - results.length)
    end
  end

  context 'periodic activity' do
    before :each do
      handshake = Gatekeeper.handshake(@client.public_key, threshold: 3, period: 5.seconds)
      @shared_secret = Base64.encode64(@client.dh_compute_key(handshake))
    end

    it 'with sane activities should not have any rejection' do
      promises = []
      results = nil
      iterations = 20

      iterations.times do |i|
        promises.push(Gatekeeper.access(@shared_secret))
        sleep 0.25
      end

      Concurrent::Promise.zip(*promises).execute.then do |_results|
        results = _results
      end.wait

      expect(results.length).to eq iterations
    end

    it 'with insane activities should be rejected' do
      promises = []
      results = nil
      iterations = 10
      successful_access = 0

      begin
        iterations.times do |i|
          promises.push(Gatekeeper.access(@shared_secret))
          successful_access = successful_access + 1
          sleep 0.1
        end
      rescue RateLimiter::Limited => e
        cost = e.message.match(/cost\: ([\d\.]+)/)
        puts "Expected: Exception raised due to exceeding cost threshold (#{sprintf('%.2f', cost[1].to_f)})"
        expect(cost[1].to_f).to be > 3
      end

      puts 'Spin waiting until usage cost falls below threshold...'
      loop do
        break if Gatekeeper.get_current_usage_cost(@shared_secret) < 3
      end

      promises.push(Gatekeeper.access(@shared_secret))
      Concurrent::Promise.zip(*promises).execute.then do |_results|
        results = _results
      end.wait

      expect(results.length).to eq(successful_access + 1)
    end
  end
end
