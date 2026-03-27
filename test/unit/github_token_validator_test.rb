# frozen_string_literal: true

require_relative '../test_helper'

class GithubTokenValidatorTest < Minitest::Test
  def test_valid_token
    Octokit::Client.any_instance.stubs(:user).returns(Struct.new(:login).new('testuser'))

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

  def test_skip_api_check_returns_true_for_non_blank_token
    assert GithubTokenValidator.valid?('any_token', skip_api_check: true)
  end

  def test_skip_api_check_returns_false_for_blank_token
    refute GithubTokenValidator.valid?(nil, skip_api_check: true)
    refute GithubTokenValidator.valid?('', skip_api_check: true)
  end
end
