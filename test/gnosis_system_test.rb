# frozen_string_literal: true

require 'test_helper'
require File.expand_path("#{File.dirname(__FILE__)}/../../../test/application_system_test_case")

class GnosisSystemTest < ApplicationSystemTestCase
  def login
    visit '/login'
    fill_in 'username', with: 'gnosis_admin'
    fill_in 'password', with: 'gnosis12345678'
    click_button 'Login'
  end
end
