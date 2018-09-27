require 'rails_helper'

RSpec.describe ServiceMessage, type: :model do
  before :each do
    ServiceMessage.reseed
  end

  it 'should load seed correctly' do
    #ap ServiceMessage.all
    ap ServiceMessage.queue
  end
end
