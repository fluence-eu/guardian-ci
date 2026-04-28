# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'rails/generators'
require 'generators/fluence_ci/install_generator'

RSpec.describe FluenceCi::InstallGenerator do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(tmpdir) }

  def run_generator(args = [])
    # Capture stdout to keep RSpec output clean — Thor's `say` writes
    # progress lines that are noise during test runs.
    original = $stdout
    $stdout = StringIO.new
    described_class.start(args, destination_root: tmpdir)
  ensure
    $stdout = original
  end

  context 'greenfield (no config/ci.rb)' do
    it 'copies the full template to config/ci.rb' do
      run_generator
      target = File.join(tmpdir, 'config/ci.rb')
      expect(File.exist?(target)).to be true
      content = File.read(target)
      expect(content).to include("require 'fluence/ci/tools/steps'")
      expect(content).to include('extend Fluence::Ci::Tools::Steps')
      expect(content).to include('all')
    end
  end

  context 'existing config/ci.rb (Rails 8.1+ default)' do
    let(:rails_default) do
      <<~RUBY
        # Run using bin/ci

        CI.run do
          step 'Setup', 'bin/setup --skip-server'
          step 'Style: Ruby', 'bin/rubocop'
          step 'Security: Gem audit', 'bin/bundler-audit'
        end
      RUBY
    end

    before do
      FileUtils.mkdir_p(File.join(tmpdir, 'config'))
      File.write(File.join(tmpdir, 'config/ci.rb'), rails_default)
    end

    it 'injects require + extend + all without removing existing steps' do
      run_generator
      content = File.read(File.join(tmpdir, 'config/ci.rb'))
      expect(content).to include("require 'fluence/ci/tools/steps'")
      expect(content).to include('extend Fluence::Ci::Tools::Steps')
      expect(content).to include('all')
      # Rails defaults preserved.
      expect(content).to include("step 'Setup', 'bin/setup --skip-server'")
      expect(content).to include("step 'Style: Ruby', 'bin/rubocop'")
    end

    it 'is idempotent on a second run' do
      run_generator
      first = File.read(File.join(tmpdir, 'config/ci.rb'))
      run_generator
      second = File.read(File.join(tmpdir, 'config/ci.rb'))
      expect(second).to eq(first)
    end
  end
end
