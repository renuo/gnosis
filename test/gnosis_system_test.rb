# frozen_string_literal: true

require 'test_helper'
require File.expand_path("#{File.dirname(__FILE__)}/../../../test/application_system_test_case")

class GnosisSystemTest < ApplicationSystemTestCase
  def login
    visit '/login'
    fill_in 'username', with: 'admin'
    fill_in 'password', with: 'admin'
    click_button 'Login'
    assert !page.has_content?('Invalid user or password')
  end
end
