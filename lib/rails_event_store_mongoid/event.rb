require 'mongoid'

module RailsEventStoreMongoid
  class Event
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'event_store_events'

    field :stream, type: String
    field :event_type, type: String
    field :event_id, type: String
    field :metadata, type: Hash
    field :data, type: Hash

    index stream: 1
    index created_at: 1
    index event_type: 1
    index({ event_id: 1 }, { unique: true })
  end
end
