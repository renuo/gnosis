# frozen_string_literal: true

require_relative '../test_helper'
class LegacyImportServiceTest < Minitest::Test
  def test
    LegacyImportService.new.call
  end
end
