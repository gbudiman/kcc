class RateExec
  def initialize throws: false, threshold: 3, period: 1.minute
    @throws = throws
    client = OpenSSL::PKey::EC.generate('secp256k1')
    handshake = RateLimiter.handshake(client.public_key, threshold: threshold, period: period)
    @shared_secret = Base64.encode64(client.dh_compute_key(handshake))
  end

  def limit sym
    begin
      RateLimiter.access(@shared_secret)
    rescue RateLimiter::Limited => e
      if @throws
        raise RateLimiter::Limited, e.message
      end
    end
  end
end