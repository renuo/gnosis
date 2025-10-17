# frozen_string_literal: true

require_relative '../test_helper'

class GithubTokenValidatorTest < Minitest::Test
  def test_valid_token
    Octokit::Client.any_instance.stubs(:user).returns(OpenStruct.new(login: 'testuser'))

    assert GithubTokenValidator.valid?('valid_token')
  end

  def test_invalid_token_unauthorized
    Octokit::Client.any_instance.stubs(:user).raises(Octokit::Unauthorized)

    refute GithubTokenValidator.valid?('invalid_token')
  end

  def test_invalid_token_forbidden
    Octokit::Client.any_instance.stubs(:user).raises(Octokit::Forbidden)

    refute GithubTokenValidator.valid?('forbidden_token')
  end

  def test_blank_token
    refute GithubTokenValidator.valid?(nil)
    refute GithubTokenValidator.valid?('')
    refute GithubTokenValidator.valid?('  ')
  end
end
