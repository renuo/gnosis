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

  # The plugin directory is a symlink in development setups. Reaching a file through
  # both the symlink and its resolved path executes its body twice.
  test 'loads each plugin file under a single path' do
    original_eager_load = Rails.application.config.eager_load
    Rails.application.config.eager_load = true
    Rails.application.eager_load!

    plugin_root = File.realpath(File.expand_path('..', __dir__))
    source_dirs = %w[app lib].map { |dir| File.join(plugin_root, dir) }
    duplicates = $LOADED_FEATURES
                 .select { |feature| File.exist?(feature) }
                 .group_by { |feature| File.realpath(feature) }
                 .select { |real, features| features.size > 1 && source_dirs.any? { |dir| real.start_with?(dir) } }

    assert_empty duplicates
  ensure
    Rails.application.config.eager_load = original_eager_load
  end
end
