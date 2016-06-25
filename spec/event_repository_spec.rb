require 'spec_helper'
require 'mongoid_event_repository_lint'

module RailsEventStoreMongoid
  describe EventRepository do
    it_behaves_like :mongoid_event_repository, EventRepository

    specify 'initialize with adapter' do
      repository = EventRepository.new
      expect(repository.adapter).to eq(Event)
    end

    specify 'provide own event implementation' do
      CustomEvent = Class.new do
        include Mongoid::Document
        include Mongoid::Timestamps
      end
      repository = EventRepository.new(adapter: CustomEvent)
      expect(repository.adapter).to eq(CustomEvent)
    end
  end
end
