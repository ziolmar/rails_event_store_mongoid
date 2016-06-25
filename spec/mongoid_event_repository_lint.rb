RSpec.shared_examples :mongoid_event_repository do |repository_class|
  TestDomainEvent = Class.new(RubyEventStore::Event)
  subject(:repository)  { repository_class.new }

  it 'just created is empty' do
    expect(repository.read_all_streams_forward(:head, 1)).to be_empty
  end

  it 'what you get is what you gave' do
    created = repository.create(event = TestDomainEvent.new, 'stream')
    expect(created.object_id).to eq event.object_id
  end

  it 'created event is stored in given stream' do
    expected_event = TestDomainEvent.new(data: {})
    created = repository.create(expected_event, 'stream')
    expect(created).to eq(expected_event)
    head_first_event = repository.read_all_streams_forward(:head, 1).first
    expect(head_first_event.event_id).to eq(expected_event.event_id)
    expect(head_first_event.metadata['timestamp'].iso8601).to eq(expected_event.metadata[:timestamp].iso8601)
    stream_first_event = repository.read_stream_events_forward('stream').first
    expect(stream_first_event.event_id).to eq(expected_event.event_id)
    expect(stream_first_event.metadata['timestamp'].iso8601).to eq(expected_event.metadata[:timestamp].iso8601)
    expect(repository.read_stream_events_forward('other_stream')).to be_empty
  end

  it 'does not have deleted streams' do
    repository.create(TestDomainEvent.new, 'stream')
    repository.create(TestDomainEvent.new, 'other_stream')

    expect(repository.read_stream_events_forward('stream').count).to eq 1
    expect(repository.read_stream_events_forward('other_stream').count).to eq 1
    expect(repository.read_all_streams_forward(:head, 10).count).to eq 2

    repository.delete_stream('stream')
    expect(repository.read_stream_events_forward('stream')).to be_empty
    expect(repository.read_stream_events_forward('other_stream').count).to eq 1
    expect(repository.read_all_streams_forward(:head, 10).count).to eq 1
  end

  it 'has or has not domain event' do
    repository.create(TestDomainEvent.new(event_id: 'just an id'), 'stream')

    expect(repository.has_event?('just an id')).to be_truthy
    expect(repository.has_event?('any other id')).to be_falsey
  end

  it 'knows last event in stream' do
    repository.create(TestDomainEvent.new(event_id: 'event 1'), 'stream')
    repository.create(TestDomainEvent.new(event_id: 'event 2'), 'stream')

    expect(repository.last_stream_event('stream').event_id).to eq('event 2')
    expect(repository.last_stream_event('other_stream')).to be_nil
  end

  it 'reads batch of events from stream forward & backward' do
    event_ids = (1..10).to_a.map(&:to_s)
    event_ids.each do |id|
      repository.create(TestDomainEvent.new(event_id: id), 'stream')
    end

    expect(repository.read_events_forward('stream', :head, 3).map(&:event_id)).to eq ['1','2','3']
    expect(repository.read_events_forward('stream', :head, 100).map(&:event_id)).to eq event_ids
    expect(repository.read_events_forward('stream', '5', 4).map(&:event_id)).to eq ['6','7','8','9']
    expect(repository.read_events_forward('stream', '5', 100).map(&:event_id)).to eq ['6','7','8','9','10']

    expect(repository.read_events_backward('stream', :head, 3).map(&:event_id)).to eq ['10','9','8']
    expect(repository.read_events_backward('stream', :head, 100).map(&:event_id)).to eq event_ids.reverse
    expect(repository.read_events_backward('stream', '5', 4).map(&:event_id)).to eq ['4','3','2','1']
    expect(repository.read_events_backward('stream', '5', 100).map(&:event_id)).to eq ['4','3','2','1']
  end


  it 'reads all stream events forward & backward' do
    repository.create(TestDomainEvent.new(event_id: '1'), 'stream')
    repository.create(TestDomainEvent.new(event_id: '2'), 'other_stream')
    repository.create(TestDomainEvent.new(event_id: '3'), 'stream')
    repository.create(TestDomainEvent.new(event_id: '4'), 'other_stream')
    repository.create(TestDomainEvent.new(event_id: '5'), 'other_stream')

    expect(repository.read_stream_events_forward('stream').map(&:event_id)).to eq ['1','3']
    expect(repository.read_stream_events_backward('stream').map(&:event_id)).to eq ['3','1']
  end

  it 'reads batch of events from all streams forward & backward' do
    event_ids = (1..10).to_a.map(&:to_s)
    event_ids.each do |id|
      repository.create(TestDomainEvent.new(event_id: id), SecureRandom.uuid)
    end

    expect(repository.read_all_streams_forward(:head, 3).map(&:event_id)).to eq ['1','2','3']
    expect(repository.read_all_streams_forward(:head, 100).map(&:event_id)).to eq event_ids
    expect(repository.read_all_streams_forward('5', 4).map(&:event_id)).to eq ['6','7','8','9']
    expect(repository.read_all_streams_forward('5', 100).map(&:event_id)).to eq ['6','7','8','9','10']

    expect(repository.read_all_streams_backward(:head, 3).map(&:event_id)).to eq ['10','9','8']
    expect(repository.read_all_streams_backward(:head, 100).map(&:event_id)).to eq event_ids.reverse
    expect(repository.read_all_streams_backward('5', 4).map(&:event_id)).to eq ['4','3','2','1']
    expect(repository.read_all_streams_backward('5', 100).map(&:event_id)).to eq ['4','3','2','1']
  end
end
