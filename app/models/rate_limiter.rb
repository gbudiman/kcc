class RateLimiter
  def initialize throws: false, threshold: 3, period: 1.minute
    @throws = throws
    client = OpenSSL::PKey::EC.generate('secp256k1')
    handshake = Gatekeeper.handshake(client.public_key, threshold: threshold, period: period)
    @shared_secret = Base64.encode64(client.dh_compute_key(handshake))
  end

  def limit sym, nonce: -1
    begin
      Gatekeeper.access(@shared_secret, symfunc: sym, nonce: nonce)
    rescue RateLimiter::Limited => e
      if @throws
        raise RateLimiter::Limited, e.message
      end
    end
  end

  def get_status sym, nonce
    return Gatekeeper.get_state(@shared_secret, sym, nonce).status
  end
end

class RateLimiter::Limited < StandardError
end

class RateLimiter::InvalidToken < StandardError
end

class RateLimiter::ExpiredToken < StandardError
end