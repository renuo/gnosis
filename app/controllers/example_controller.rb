# frozen_string_literal: true

class ExampleController < ApplicationController
  def index
    render plain: 'Hello, World!'
  end
end
