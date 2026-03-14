# frozen_string_literal: true

module Gnosis
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = 'gnosis_'
  end
end
