# カバレッジ（テストが通った行の割合）を測る（#33）。いちばん最初に読み込む必要がある
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
end

# RSpec 全体の基本設定（Rails を読み込まないテストでも使う）
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
