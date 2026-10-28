# frozen_string_literal: true

require_relative '../test_helper'

class GithubRepositoryTest < ActiveSupport::TestCase
  def test_parse_accepts_the_shapes_used_in_redmine
    {
      'https://github.com/renuo/bbva-hyperuploader' => 'renuo/bbva-hyperuploader',
      'https://www.github.com/renuo/foo' => 'renuo/foo',
      'http://github.com/renuo/foo' => 'renuo/foo',
      'https://github.com/renuo/foo.git' => 'renuo/foo',
      'https://github.com/renuo/foo/tree/main' => 'renuo/foo',
      'git@github.com:renuo/foo.git' => 'renuo/foo',
      'renuo/fredi' => 'renuo/fredi',
      '  renuo/fredi  ' => 'renuo/fredi',
      'fredi' => 'renuo/fredi'
    }.each do |value, expected|
      assert_equal expected, Gnosis::GithubRepository.parse(value).full_name, "failed for #{value.inspect}"
    end
  end

  def test_parse_rejects_blank_and_foreign_hosts
    ['', '   ', nil, 'https://gitlab.com/renuo/foo', 'git@gitlab.com:renuo/foo.git'].each do |value|
      assert_nil Gnosis::GithubRepository.parse(value), "expected #{value.inspect} to be rejected"
    end
  end

  def test_urls
    repository = Gnosis::GithubRepository.parse('renuo/foo')

    assert_equal 'renuo', repository.owner
    assert_equal 'foo', repository.name
    assert_equal 'renuo/foo', repository.to_s
    assert_equal 'https://github.com/renuo/foo', repository.url
    assert_equal 'https://github.com/renuo/foo/compare/main...develop', repository.compare_url('main', 'develop')
    assert_equal 'https://github.com/renuo/foo/releases/tag/1.2.3', repository.tag_url('1.2.3')
  end

  def test_equality
    assert_equal Gnosis::GithubRepository.parse('renuo/foo'), Gnosis::GithubRepository.parse('renuo/foo')
    assert_not_equal Gnosis::GithubRepository.parse('renuo/foo'), Gnosis::GithubRepository.parse('renuo/bar')
    assert_not_equal Gnosis::GithubRepository.parse('renuo/foo'), 'renuo/foo'
  end

  def test_for_project_without_the_custom_field
    assert_nil Gnosis::GithubRepository.for(Project.first)
  end

  def test_for_project_with_a_blank_custom_field
    create_custom_field
    assert_nil Gnosis::GithubRepository.for(Project.first)
  end

  def test_for_project_with_a_configured_repository
    project = Project.first
    field = create_custom_field
    project.custom_field_values = { field.id => 'renuo/foo' }
    project.save!

    assert_equal 'renuo/foo', Gnosis::GithubRepository.for(project).full_name
  end

  private

  def create_custom_field
    ProjectCustomField.find_or_create_by!(name: Gnosis::GithubRepository::CUSTOM_FIELD_NAME) do |field|
      field.field_format = 'string'
    end
  end
end
