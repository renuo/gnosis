# frozen_string_literal: true

require_relative '../test_helper'

class ExampleControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_response :success
  end
end
