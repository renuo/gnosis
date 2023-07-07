# frozen_string_literal: true

class NumberExtractor
  DIG_FIND_DATA = [
    { keys: %i[pull_request head ref], match_regex: %r{/(\d+)} },
    { keys: %i[pull_request body], match_regex: /TICKET-(\d+)/ },
  ].freeze

  def self.call(params)
    DIG_FIND_DATA.lazy.map do |data|
      match = params.dig(*data[:keys])&.match(data[:match_regex])
      match[1] if match
      # rubocop:disable Style/CollectionCompact
    end.reject(&:nil?).first
    # rubocop:enable Style/CollectionCompact
  end
end
