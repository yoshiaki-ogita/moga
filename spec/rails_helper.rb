# Rails を読み込むテスト用の設定（モデル・リクエストのテストで require する）
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # FactoryBot の create(:user) などを、FactoryBot. を付けずに書けるようにする
  config.include FactoryBot::Syntax::Methods

  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!

  # system spec（#32）はブラウザを使わず rack_test で動かす（Docker や CI に Chrome を入れなくて済む）
  config.before(type: :system) do
    driven_by :rack_test
  end
end
