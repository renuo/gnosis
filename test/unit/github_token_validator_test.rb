# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/mock'

class GithubTokenValidatorTest < Minitest::Test
  def test_valid_token
    mock_client = Minitest::Mock.new
    mock_client.expect :user, OpenStruct.new(login: 'testuser')
    
    Octokit::Client.stub :new, mock_client do
      assert GithubTokenValidator.valid?('valid_token')
    end
    
    mock_client.verify
  end

  def test_invalid_token_unauthorized
    mock_client = Minitest::Mock.new
    mock_client.expect :user, -> { raise Octokit::Unauthorized }
    
    Octokit::Client.stub :new, mock_client do
      refute GithubTokenValidator.valid?('invalid_token')
    end
    
    mock_client.verify
  end

  def test_invalid_token_forbidden
    mock_client = Minitest::Mock.new
    mock_client.expect :user, -> { raise Octokit::Forbidden }
    
    Octokit::Client.stub :new, mock_client do
      refute GithubTokenValidator.valid?('forbidden_token')
    end
    
    mock_client.verify
  end

  def test_blank_token
    refute GithubTokenValidator.valid?(nil)
    refute GithubTokenValidator.valid?('')
    refute GithubTokenValidator.valid?('  ')
  end
end
