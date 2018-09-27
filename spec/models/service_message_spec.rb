require 'rails_helper'

RSpec.describe ServiceMessage, type: :model do
  before :each do
    ServiceMessage.reseed
  end

  it 'should load seed correctly' do
    queue = ServiceMessage.queue
    inflights = ServiceMessage.inflights
    statuses = queue.pluck('status').uniq
    recipients = queue.pluck('medium', 'identifier')


    # ensure only one message per recipient
    expect(recipients.uniq).to eq recipients

    # ensure result doesn't contain recipient that has inflight messages
    expect(recipients).not_to include(inflights)

    # ensure result only contain pending messages
    expect(statuses).to contain_exactly(ServiceMessage.statuses[:pending])
  end
end
