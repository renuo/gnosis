# frozen_string_literal: true

require 'test_helper'
require 'selenium-webdriver'

# Selenium Manager resolves a browser and a matching driver, but ActionDispatch's Browser#preload
# keeps only the driver path and pins it on Chrome::Service, which makes the lookup at session
# time skip the manager and leave the browser unset — chromedriver then falls back to a
# system-wide Chrome. Resolving both up front keeps the pair consistent, whether that is the
# system Chrome with the chromedriver from PATH or a Chrome for Testing build downloaded to
# ~/.cache/selenium when the system has neither. Rails 8.0 sets the browser itself
# (rails/rails#50296 and its follow-up), so this can go once Redmine moves off Rails 7.2.
chrome = Selenium::WebDriver::DriverFinder.new(Selenium::WebDriver::Options.chrome,
                                               Selenium::WebDriver::Chrome::Service.new)
Selenium::WebDriver::Chrome.path = chrome.browser_path
Selenium::WebDriver::Chrome::Service.driver_path = chrome.driver_path

require File.expand_path("#{File.dirname(__FILE__)}/../../../test/application_system_test_case")

class GnosisSystemTest < ApplicationSystemTestCase
  def login
    visit '/login'
    fill_in 'username', with: 'admin'
    fill_in 'password', with: 'admin'
    click_button 'Login'
    assert_not page.has_content?('Invalid user or password')
  end
end
