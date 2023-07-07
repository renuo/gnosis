class NumberExtractor
  DIG_FIND_DATA = [
    { keys: %i[pull_request head ref], match_regex: /\/(\d+)/ },
    { keys: %i[pull_request body], match_regex: /TICKET-(\d+)/ },
  ]

  def self.call(params)
    DIG_FIND_DATA.lazy.map do |data|
      match = params.dig(*data[:keys])&.match(data[:match_regex])
      match[1] if match
    end.reject(&:nil?).first
  end
end
