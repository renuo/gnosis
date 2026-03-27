# frozen_string_literal: true

require_relative '../test_helper'

class GithubTokenValidatorTest < ActiveSupport::TestCase
  def test_valid_token
    Octokit::Client.any_instance.stubs(:user).returns(Struct.new(:login).new('testuser'))

    assert GithubTokenValidator.valid?('valid_token')
  end

  def test_invalid_token_unauthorized
    Octokit::Client.any_instance.stubs(:user).raises(Octokit::Unauthorized)

    assert_not GithubTokenValidator.valid?('invalid_token')
  end

  def test_invalid_token_forbidden
    Octokit::Client.any_instance.stubs(:user).raises(Octokit::Forbidden)

    assert_not GithubTokenValidator.valid?('forbidden_token')
  end

  def test_blank_token
    assert_not GithubTokenValidator.valid?(nil)
    assert_not GithubTokenValidator.valid?('')
    assert_not GithubTokenValidator.valid?('  ')
  end
end
