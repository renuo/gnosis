# frozen_string_literal: true

require_relative '../test_helper'
require 'open3'
require 'tmpdir'

class SetupRedmineTest < ActiveSupport::TestCase
  SCRIPT = File.expand_path('../../bin/setup_redmine', __dir__)

  setup do
    @dir = Dir.mktmpdir('gnosis-setup-redmine')
    @redmine = File.join(@dir, 'redmine')
    fake_redmine_checkout(@redmine, branch: '6.0-stable')
  end

  teardown { FileUtils.rm_rf(@dir) }

  test 'accepts an existing checkout on the requested branch and writes the configs' do
    out, err, status = setup_redmine('6.0-stable', @redmine)

    assert_predicate status, :success?, err
    assert_equal @redmine, out.strip
    assert File.exist?(File.join(@redmine, 'config', 'configuration.yml'))
    assert_includes File.read(File.join(@redmine, 'config', 'database.yml')), 'adapter: postgresql'
  end

  test 'accepts an existing checkout when no version is requested' do
    _out, err, status = setup_redmine(nil, @redmine)

    assert_predicate status, :success?, err
  end

  test 'accepts a detached checkout of the requested tag' do
    git(@redmine, 'tag', '6.0.5')
    git(@redmine, 'checkout', '-q', '--detach', '6.0.5')

    _out, err, status = setup_redmine('6.0.5', @redmine)

    assert_predicate status, :success?, err
  end

  test 'fails when the existing checkout is not on the requested version' do
    _out, err, status = setup_redmine('master', @redmine)

    assert_not_predicate status, :success?
    assert_match(/is on 6\.0-stable \(\h{7}\), not master\. Remove it to switch\./, err)
  end

  test 'fails before cloning when the target is not empty and not a Redmine checkout' do
    target = File.join(@dir, 'something-else')
    FileUtils.mkdir_p(target)
    File.write(File.join(target, 'README'), '')

    _out, err, status = setup_redmine('6.0-stable', target)

    assert_not_predicate status, :success?
    assert_includes err, "#{target} exists but is not a Redmine checkout."
    assert_not File.exist?(File.join(target, 'lib', 'redmine.rb'))
  end

  test 'leaves existing configs untouched' do
    database_yml = File.join(@redmine, 'config', 'database.yml')
    File.write(database_yml, "custom: true\n")

    _out, err, status = setup_redmine('6.0-stable', @redmine)

    assert_predicate status, :success?, err
    assert_equal "custom: true\n", File.read(database_yml)
  end

  private

  def setup_redmine(version, target)
    Open3.capture3({ 'REDMINE_VERSION' => nil }, SCRIPT, version.to_s, target)
  end

  def fake_redmine_checkout(path, branch:)
    FileUtils.mkdir_p(File.join(path, 'lib'))
    FileUtils.mkdir_p(File.join(path, 'config'))
    File.write(File.join(path, 'lib', 'redmine.rb'), '')
    File.write(File.join(path, 'config', 'configuration.yml.example'), "default:\n")
    git(path, 'init', '-q', '-b', branch)
    git(path, 'add', '.')
    git(path, 'commit', '-q', '-m', 'Redmine')
  end

  def git(path, *args)
    system('git', '-C', path, '-c', 'user.name=test', '-c', 'user.email=test@example.com',
           '-c', 'commit.gpgsign=false', *args, exception: true, out: File::NULL)
  end
end
