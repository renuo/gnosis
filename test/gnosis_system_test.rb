# frozen_string_literal: true

require 'test_helper'
require File.expand_path("#{File.dirname(__FILE__)}/../../../test/application_system_test_case")

class GnosisSystemTest < ApplicationSystemTestCase
  def login
    User.where(login: 'admin').each do |user|
      user.update!(password: '12345678')
    end

    visit '/login'
    fill_in 'username', with: 'admin'
    fill_in 'password', with: '12345678'
    click_button 'Login'
  end
end
