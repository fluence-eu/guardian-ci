# frozen_string_literal: true

# Generate per-Rails-version Gemfiles for CI. Regenerate with:
#   bundle exec appraisal install
#
# The set of Rails versions tested here must stay in sync with the
# matrix in .github/workflows/main.yml. Older Rails minors stay in
# scope as long as Rails::Generators::Base remains source-stable.

appraise 'rails-7.0' do
  gem 'rails', '~> 7.0.0'
end

appraise 'rails-7.1' do
  gem 'rails', '~> 7.1.0'
end

appraise 'rails-7.2' do
  gem 'rails', '~> 7.2.0'
end

appraise 'rails-8.0' do
  gem 'rails', '~> 8.0.0'
end

appraise 'rails-8.1' do
  gem 'rails', '~> 8.1.0'
end
