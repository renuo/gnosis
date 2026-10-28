# frozen_string_literal: true

module Gnosis
  class ReleaseVersion
    include Comparable

    SCHEMA = /\A(?<prefix>v?)(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\z/.freeze
    UPDATE_TYPES = %w[patch minor major custom].freeze
    INITIAL = '0.0.0'

    attr_reader :major, :minor, :patch, :prefix

    def self.parse(value)
      match = SCHEMA.match(value.to_s.strip)
      return if match.nil?

      new(match[:major].to_i, match[:minor].to_i, match[:patch].to_i, prefix: match[:prefix])
    end

    def self.latest(names)
      names.filter_map { |name| parse(name) }.max
    end

    def initialize(major, minor, patch, prefix: '')
      @major = major
      @minor = minor
      @patch = patch
      @prefix = prefix
    end

    def bump(update_type)
      case update_type
      when 'patch' then self.class.new(major, minor, patch + 1, prefix: prefix)
      when 'minor' then self.class.new(major, minor + 1, 0, prefix: prefix)
      when 'major' then self.class.new(major + 1, 0, 0, prefix: prefix)
      end
    end

    # A custom version is typed by hand, so it usually omits the "v" the repository tags carry.
    def with_prefix_of(other)
      return self if prefix.present?

      self.class.new(major, minor, patch, prefix: other.prefix)
    end

    def <=>(other)
      [major, minor, patch] <=> [other.major, other.minor, other.patch]
    end

    def to_s
      "#{prefix}#{major}.#{minor}.#{patch}"
    end
  end
end
