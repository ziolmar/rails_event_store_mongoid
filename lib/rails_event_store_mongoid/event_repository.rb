module RailsEventStoreMongoid
  class EventRepository
    def initialize(adapter: ::RailsEventStoreMongoid::Event)
      @adapter = adapter
    end
    attr_reader :adapter

    def create(event, stream_name)
      data = event.to_h.merge!(stream: stream_name, event_type: event.class.name)
      adapter.create(data)
      event
    end

    def delete_stream(stream_name)
      condition = {stream: stream_name}
      adapter.destroy_all condition
      nil
    end

    def has_event?(event_id)
      adapter.where(event_id: event_id).exists?
    end

    def last_stream_event(stream_name)
      build_event_entity(adapter.where(stream: stream_name).order_by(created_at: :asc).last)
    end

    def get_all_events
      adapter.order_by(created_at: :asc, stream: :asc).map(&method(:build_event_entity))
    end

    def read_events_forward(stream_name, start_event_id, count)
      stream = adapter.where(stream: stream_name)
      unless start_event_id.equal?(:head)
        starting_event = adapter.find_by(event_id: start_event_id)
        stream = stream.where(:created_at.gt => starting_event.created_at)
      end

      stream.order_by(created_at: :asc).limit(count)
        .map(&method(:build_event_entity))
    end

    def read_events_backward(stream_name, start_event_id, count)
      stream = adapter.where(stream: stream_name)
      unless start_event_id.equal?(:head)
        starting_event = adapter.find_by(event_id: start_event_id)
        stream = stream.where(:created_at.lt => starting_event.created_at)
      end

      stream.order_by(created_at: :desc).limit(count)
        .map(&method(:build_event_entity))
    end

    def read_stream_events_forward(stream_name)
      adapter.where(stream: stream_name).order_by(created_at: :asc)
        .map(&method(:build_event_entity))
    end

    def read_stream_events_backward(stream_name)
      adapter.where(stream: stream_name).order_by(created_at: :desc)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_forward(start_event_id, count)
      stream = adapter
      unless start_event_id.equal?(:head)
        starting_event = adapter.find_by(event_id: start_event_id)
        stream = stream.where(:created_at.gt => starting_event.created_at)
      end

      stream.order_by(created_at: :asc).limit(count)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_backward(start_event_id, count)
      stream = adapter
      unless start_event_id.equal?(:head)
        starting_event = adapter.find_by(event_id: start_event_id)
        stream = stream.where(:created_at.lt => starting_event.created_at)
      end

      stream.order_by(created_at: :desc).limit(count)
        .map(&method(:build_event_entity))
    end

    private

    def build_event_entity(record)
      return nil unless record
      record.event_type.constantize.new(
        record.data.to_h.merge(
          event_id: record.event_id,
          metadata: record.metadata
        )
      )
    end
  end
end
