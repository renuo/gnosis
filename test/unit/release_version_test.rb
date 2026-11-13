# frozen_string_literal: true

require_relative '../test_helper'

class ReleaseVersionTest < ActiveSupport::TestCase
  def test_parse_plain_version
    version = Gnosis::ReleaseVersion.parse('1.4.2')

    assert_equal 1, version.major
    assert_equal 4, version.minor
    assert_equal 2, version.patch
    assert_equal '1.4.2', version.to_s
  end

  def test_parse_keeps_the_v_prefix
    assert_equal 'v2.0.1', Gnosis::ReleaseVersion.parse('v2.0.1').to_s
  end

  def test_parse_ignores_surrounding_whitespace
    assert_equal '1.0.0', Gnosis::ReleaseVersion.parse("  1.0.0\n").to_s
  end

  def test_parse_rejects_anything_that_is_not_semver
    ['', nil, '1.2', '1.2.3.4', 'release-1.2.3', '1.2.3-rc1'].each do |value|
      assert_nil Gnosis::ReleaseVersion.parse(value), "expected #{value.inspect} to be rejected"
    end
  end

  def test_latest_picks_the_highest_version_and_skips_junk
    names = %w[1.9.0 not-a-version 1.10.0 0.1.0 latest]

    assert_equal '1.10.0', Gnosis::ReleaseVersion.latest(names).to_s
  end

  def test_latest_without_any_version_tag
    assert_nil Gnosis::ReleaseVersion.latest(%w[latest stable])
  end

  def test_bump
    version = Gnosis::ReleaseVersion.parse('1.4.2')

    assert_equal '1.4.3', version.bump('patch').to_s
    assert_equal '1.5.0', version.bump('minor').to_s
    assert_equal '2.0.0', version.bump('major').to_s
  end

  def test_bump_keeps_the_prefix
    assert_equal 'v1.5.0', Gnosis::ReleaseVersion.parse('v1.4.2').bump('minor').to_s
  end

  def test_bump_is_undefined_for_a_custom_release
    assert_nil Gnosis::ReleaseVersion.parse('1.4.2').bump('custom')
  end

  def test_with_prefix_of_adopts_the_prefix_when_missing
    assert_equal 'v2.0.0', Gnosis::ReleaseVersion.parse('2.0.0')
                                                 .with_prefix_of(Gnosis::ReleaseVersion.parse('v1.4.2')).to_s
  end

  def test_with_prefix_of_keeps_an_explicit_prefix
    version = Gnosis::ReleaseVersion.parse('v2.0.0')

    assert_same version, version.with_prefix_of(Gnosis::ReleaseVersion.parse('1.4.2'))
  end

  def test_comparison
    assert_operator Gnosis::ReleaseVersion.parse('1.10.0'), :>, Gnosis::ReleaseVersion.parse('1.9.9')
    assert_equal Gnosis::ReleaseVersion.parse('1.0.0'), Gnosis::ReleaseVersion.parse('v1.0.0')
  end
end
