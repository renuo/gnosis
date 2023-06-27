# frozen_string_literal: true

require 'test_helper'

class ZeitwerkComplianceTest < ActiveSupport::TestCase
  test 'eager loads all files without errors' do
    original_eager_load = Rails.application.config.eager_load
    Rails.application.config.eager_load = true
    assert_nothing_raised { Rails.application.eager_load! }
  ensure
    Rails.application.config.eager_load = original_eager_load
  end
end
