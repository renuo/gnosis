# frozen_string_literal: true

module Gnosis
  class GithubRepository
    CUSTOM_FIELD_NAME = 'Github Repository'
    DEFAULT_OWNER = 'renuo'
    HOST = 'github.com'

    attr_reader :owner, :name

    def self.for(project)
      custom_field = ProjectCustomField.find_by(name: CUSTOM_FIELD_NAME)
      return if custom_field.nil?

      parse(project.custom_field_value(custom_field))
    end

    # Accepts the shapes found in the wild: "https://github.com/renuo/foo", "git@github.com:renuo/foo.git",
    # "renuo/foo" and the bare "foo".
    def self.parse(value)
      segments = path_segments(value)
      return if segments.nil?

      case segments.size
      when 1 then new(DEFAULT_OWNER, segments.first)
      else new(segments.first, segments.second)
      end
    end

    def self.path_segments(value)
      path = value.to_s.strip
      return if path.blank?

      path = path.sub(/\Agit@#{Regexp.escape(HOST)}:/o, '')
                 .sub(%r{\Ahttps?://(www\.)?#{Regexp.escape(HOST)}/}o, '')
                 .delete_suffix('.git')
      return if path.include?('://') || path.include?('@')

      segments = path.split('/').reject(&:blank?)
      segments.presence
    end
    private_class_method :path_segments

    def initialize(owner, name)
      @owner = owner
      @name = name
    end

    def full_name
      "#{owner}/#{name}"
    end
    alias to_s full_name

    def url
      "https://#{HOST}/#{full_name}"
    end

    def compare_url(base, head)
      "#{url}/compare/#{base}...#{head}"
    end

    def tag_url(tag)
      "#{url}/releases/tag/#{tag}"
    end

    def ==(other)
      other.is_a?(self.class) && other.full_name == full_name
    end
  end
end
