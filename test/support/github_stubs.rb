# frozen_string_literal: true

# Minimal stand-ins for the Sawyer resources Octokit returns, so the release tests can describe a repository
# without talking to GitHub.
module GithubStubs
  Author = Struct.new(:name, keyword_init: true)
  Blob = Struct.new(:content, keyword_init: true)
  Comparison = Struct.new(:commits, :files, keyword_init: true)
  Commit = Struct.new(:sha, :html_url, :commit, keyword_init: true)
  CommitDetail = Struct.new(:message, :author, :tree, keyword_init: true)
  Ref = Struct.new(:object, keyword_init: true)
  Repository = Struct.new(:default_branch, keyword_init: true)
  SearchItem = Struct.new(:path, keyword_init: true)
  SearchResult = Struct.new(:items, keyword_init: true)
  Sha = Struct.new(:sha, keyword_init: true)
  Tag = Struct.new(:name, keyword_init: true)
  Tree = Struct.new(:tree, keyword_init: true)
  TreeEntry = Struct.new(:path, :type, :sha, :mode, keyword_init: true)

  REPOSITORY = 'renuo/foo'

  def github_repository
    Gnosis::GithubRepository.parse(REPOSITORY)
  end

  def github_commit(sha, message, author: 'Alessandro')
    Commit.new(sha: sha, html_url: "https://github.com/#{REPOSITORY}/commit/#{sha}",
               commit: CommitDetail.new(message: message, author: Author.new(name: author)))
  end

  def github_comparison(commits: [github_commit('abc1234', 'Fix invoice rounding')], files: [Object.new])
    Comparison.new(commits: commits, files: files)
  end

  def github_tree(*paths)
    Tree.new(tree: paths.map do |path|
      TreeEntry.new(path: path, type: 'blob', sha: "sha-#{path}", mode: '100644')
    end)
  end

  def github_blob(content)
    Blob.new(content: Base64.encode64(content))
  end

  def github_ref(sha)
    Ref.new(object: Sha.new(sha: sha))
  end
end
